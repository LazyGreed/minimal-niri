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

wallpaper_source=$HOME/minimal-niri/Wallpapers
wallpaper_dest=$HOME/Pictures/Wallpapers
if [ -d "$wallpaper_dest" ]; then
    echo "Wallpapers destination folder exist. Copying content..."
    cp -v "$wallpaper_source"/* "$wallpaper_dest"
    echo "Wallpapers copied."
else
    echo "'$wallpaper_dest' not found. Creating it now..."
    mkdir -p "$wallpaper_source"

    if [ $? -eq 0 ]; then
        echo "'$wallpaper_dest' created successfully. Copying content..."
        cp -r "$wallpaper_source"/* "$wallpaper_dest"
        echo "Wallpapers copied."
    else
        echo "Error in creating '$wallpaper_dest'."
        exit 1
    fi
fi

echo "Script finished!!!"

