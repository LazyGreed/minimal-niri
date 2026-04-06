# My minimal niri setup on CachyOS

## Packages

Some of these packages maybe unnecessary

```bash
paru -S libva-utils sddm niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk kitty tmux neovim telegram-desktop visual-studio-code-bin antigravity zen-browser-bin yazi github-cli udiskie fuzzel hyprlock tailscale catppuccin-gtk-theme-mocha nwg-look qt5ct qt6ct kvantum kvantum-qt5 polkit-gnome ttf-jetbrains-mono-nerd ttf-fira-code waybar mako brightnessctl catppuccin-cursors-mocha whitesur-icon-theme uv mpv wl-clipboard gdu glow --noconfirm
```

## Dotfile Sync Workflow

This repo manages `config/*` as dotfiles mapped to `~/.config/*`.

Use the script at the repo root:

```bash
./dotfiles.sh status
./dotfiles.sh install --dry-run
./dotfiles.sh install
./dotfiles.sh update --dry-run
./dotfiles.sh update
```

### Commands

- `install`: symlink each repo `config/<name>` to `~/.config/<name>`.
- `update`: pull changes from `~/.config/<name>` back into repo `config/<name>`.
- `status`: show link state and whether repo entries need update.

### Flags

- `-n, --dry-run`: preview actions without writing changes.
- `-v, --verbose`: print additional logs.
- `-f, --force`: replace existing `~/.config/<name>` entries without backup.
- `-d, --delete`: with `update`, delete files in repo that do not exist in `~/.config`.

## Credit

- [tony](https://github.com/tonybanters/) - for nvim, waybar and tmux theme
- [Catppuccin](https://github.com/catppuccin/) - for catppuccin themes
