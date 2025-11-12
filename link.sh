#!/usr/bin/env bash

for folder in ~/minimal-niri/.config/*/; do
    # Get the folder name (basename)
    # The / at the end of the glob ensures only directories are matched,
    # and parameter expansion removes the trailing slash for the link name.
    folder_name=$(basename "${folder%/}")
    
    # Check if a link or file/directory with the same name already exists in ~/.config
    if [ -e ~/.config/"$folder_name" ] || [ -L ~/.config/"$folder_name" ]; then
        echo "Backup '$folder_name': Because target ~/.config/$folder_name already exists."
        mv ~/.config/$folder_name ~/.config/$folder_name.bak
    fi
    
    # Create the symbolic link (-s for symbolic, -v for verbose output)
    echo "Creating symlink: $folder_name"
    ln -sv "$folder" ~/.config/"$folder_name"
done
