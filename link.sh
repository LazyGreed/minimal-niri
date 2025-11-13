#!/usr/bin/env bash

for folder in ~/minimal-niri/.config/*/; do
    folder_name=$(basename "${folder%/}")
    
    if [ -e ~/.config/"$folder_name" ] || [ -L ~/.config/"$folder_name" ]; then
        echo "Backup '$folder_name': Because target ~/.config/$folder_name already exists."
        mv ~/.config/$folder_name ~/.config/$folder_name.bak
    fi
    
    echo "Creating symlink: $folder_name"
    ln -sv "$folder" ~/.config/"$folder_name"
done
