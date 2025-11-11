#!/usr/bin/bash

sudo pacman -Syu --noconfirm

paru -S --noconfirm niri waybar brightnessctl rofi hyprlock swww matugen network-manager-applet kitty cava btop dunst sweet-gtk-theme-dark catppuccin-cursors-mocha candy-icons-git qt6ct-kde 

for d in ~/minimal-niri/.config/*; do
    mv ~/.config/$d ~/.config/$d.bak
    cp -r ~/minimal-niri/.config/$d ~/.config/
done

gsettings set org.gnome.desktop.interface gtk-theme Sweet-Dark
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface icon-theme candy-icons

