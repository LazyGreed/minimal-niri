#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$SCRIPT_DIR"
MANAGED_ROOT="$REPO_ROOT/config"
HOME_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/minimal-niri-backups"

MODE=""
DRY_RUN=false
VERBOSE=false
FORCE=false
DELETE_MISSING=false

usage() {
  cat <<'EOF'
Usage: ./dotfiles.sh <command> [options]

Commands:
  install        Symlink repo config/* into ~/.config
  update         Sync ~/.config managed entries back into repo config/*
  status         Show install/link and sync drift status

Options:
  -n, --dry-run  Show actions without changing files
  -v, --verbose  Print extra logs
  -f, --force    Overwrite conflicting ~/.config entries without backup
  -d, --delete   With update, delete files in repo missing from ~/.config
  -h, --help     Show this help

Notes:
  - Managed scope is repo config/* <-> ~/.config/* only.
  - install backs up conflicting paths into:
      ${XDG_STATE_HOME:-$HOME/.local/state}/minimal-niri-backups/<timestamp>/
  - update treats ~/.config as source of truth.
EOF
}

log() {
  printf '[%s] %s\n' "$1" "$2"
}

debug() {
  if "$VERBOSE"; then
    log "debug" "$1"
  fi
}

die() {
  log "error" "$1"
  exit 1
}

action_log() {
  local done_msg="$1"
  local dry_run_msg="$2"
  if "$DRY_RUN"; then
    log "info" "$dry_run_msg"
  else
    log "info" "$done_msg"
  fi
}

run_cmd() {
  if "$DRY_RUN"; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
}

collect_managed_entries() {
  mapfile -t MANAGED_ENTRIES < <(find "$MANAGED_ROOT" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)
  ((${#MANAGED_ENTRIES[@]} > 0)) || die "No managed entries found under $MANAGED_ROOT"
}

trim_line() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "$line"
}

collect_rsync_excludes() {
  local target_root="$1"
  local ignore_file="$target_root/.gitignore"
  RSYNC_EXCLUDES=()

  [[ -f "$ignore_file" ]] || return 0

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    local line
    line="$(trim_line "$raw")"
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    RSYNC_EXCLUDES+=("--exclude=$line")
  done <"$ignore_file"
}

same_realpath() {
  local a="$1"
  local b="$2"
  local real_a
  local real_b

  [[ -e "$a" || -L "$a" ]] || return 1
  [[ -e "$b" || -L "$b" ]] || return 1

  real_a="$(readlink -f -- "$a")"
  real_b="$(readlink -f -- "$b")"
  [[ "$real_a" == "$real_b" ]]
}

backup_path() {
  local source_path="$1"
  local stamp="$2"
  local rel="${source_path#$HOME_CONFIG/}"
  local destination="$BACKUP_ROOT/$stamp/$rel"

  run_cmd mkdir -p -- "$(dirname -- "$destination")"
  run_cmd mv -- "$source_path" "$destination"
  action_log \
    "Backed up $source_path -> $destination" \
    "Would back up $source_path -> $destination"
}

install_entry() {
  local name="$1"
  local source="$MANAGED_ROOT/$name"
  local dest="$HOME_CONFIG/$name"
  local stamp="$2"

  if [[ -L "$dest" ]] && same_realpath "$source" "$dest"; then
    debug "$name already linked"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if "$FORCE"; then
      run_cmd rm -rf -- "$dest"
      action_log "Removed existing $dest" "Would remove existing $dest"
    else
      backup_path "$dest" "$stamp"
    fi
  fi

  run_cmd ln -s -- "$source" "$dest"
  action_log "Linked $dest -> $source" "Would link $dest -> $source"
}

update_entry() {
  local name="$1"
  local source="$HOME_CONFIG/$name"
  local target="$MANAGED_ROOT/$name"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    log "warn" "Skipping missing source: $source"
    return 0
  fi

  if same_realpath "$source" "$target"; then
    debug "$name source and target resolve to same path; skipping"
    return 0
  fi

  collect_rsync_excludes "$target"

  local -a rsync_args
  rsync_args=(--archive --human-readable --itemize-changes)
  if "$DRY_RUN"; then
    rsync_args+=(--dry-run)
  fi
  if "$DELETE_MISSING"; then
    rsync_args+=(--delete)
  fi
  rsync_args+=("${RSYNC_EXCLUDES[@]}")

  if [[ -d "$source" ]]; then
    run_cmd rsync "${rsync_args[@]}" -- "$source/" "$target/"
  else
    run_cmd rsync "${rsync_args[@]}" -- "$source" "$target"
  fi
  action_log "Updated $target from $source" "Would update $target from $source"
}

entry_needs_update() {
  local name="$1"
  local source="$HOME_CONFIG/$name"
  local target="$MANAGED_ROOT/$name"
  local output

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    printf 'source-missing'
    return 0
  fi

  if same_realpath "$source" "$target"; then
    printf 'linked-live'
    return 0
  fi

  collect_rsync_excludes "$target"

  if [[ -d "$source" ]]; then
    output="$(rsync --archive --itemize-changes --dry-run "${RSYNC_EXCLUDES[@]}" -- "$source/" "$target/" | sed '/^sending incremental file list$/d;/^sent /d;/^total size is /d;/^$/d')"
  else
    output="$(rsync --archive --itemize-changes --dry-run "${RSYNC_EXCLUDES[@]}" -- "$source" "$target" | sed '/^sending incremental file list$/d;/^sent /d;/^total size is /d;/^$/d')"
  fi

  if [[ -n "$output" ]]; then
    printf 'needs-update'
  else
    printf 'in-sync'
  fi
}

install_state() {
  local name="$1"
  local source="$MANAGED_ROOT/$name"
  local dest="$HOME_CONFIG/$name"

  if [[ -L "$dest" ]] && same_realpath "$source" "$dest"; then
    printf 'linked'
    return 0
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    printf 'exists-unlinked'
    return 0
  fi
  printf 'missing'
}

status_entry() {
  local name="$1"
  local state_install
  local state_update

  state_install="$(install_state "$name")"
  state_update="$(entry_needs_update "$name")"

  printf '%-12s install=%-14s update=%s\n' "$name" "$state_install" "$state_update"
}

parse_args() {
  ((${#@} > 0)) || {
    usage
    exit 1
  }

  while (($# > 0)); do
    case "$1" in
      install | update | status)
        [[ -z "$MODE" ]] || die "Only one command is allowed"
        MODE="$1"
        ;;
      -n | --dry-run)
        DRY_RUN=true
        ;;
      -v | --verbose)
        VERBOSE=true
        ;;
      -f | --force)
        FORCE=true
        ;;
      -d | --delete)
        DELETE_MISSING=true
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done

  [[ -n "$MODE" ]] || die "No command provided"
}

main() {
  parse_args "$@"

  [[ -d "$MANAGED_ROOT" ]] || die "Managed root not found: $MANAGED_ROOT"

  require_cmd find
  require_cmd sort
  require_cmd ln
  require_cmd readlink
  if [[ "$MODE" == "install" ]] && ! "$FORCE"; then
    require_cmd mv
  fi
  if [[ "$MODE" == "update" || "$MODE" == "status" ]]; then
    require_cmd rsync
    require_cmd sed
  fi

  if [[ "$MODE" == "install" ]]; then
    run_cmd mkdir -p -- "$HOME_CONFIG"
  elif [[ ! -d "$HOME_CONFIG" ]]; then
    die "Config directory does not exist: $HOME_CONFIG"
  fi

  collect_managed_entries

  local failures=0
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"

  for entry in "${MANAGED_ENTRIES[@]}"; do
    case "$MODE" in
      install)
        if ! install_entry "$entry" "$stamp"; then
          failures=$((failures + 1))
          log "error" "Failed install for $entry"
        fi
        ;;
      update)
        if ! update_entry "$entry"; then
          failures=$((failures + 1))
          log "error" "Failed update for $entry"
        fi
        ;;
      status)
        if ! status_entry "$entry"; then
          failures=$((failures + 1))
          log "error" "Failed status for $entry"
        fi
        ;;
      *)
        die "Unsupported mode: $MODE"
        ;;
    esac
  done

  if ((failures > 0)); then
    die "Completed with $failures failure(s)"
  fi
}

main "$@"