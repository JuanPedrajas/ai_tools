#!/bin/bash

# Check for dependencies
if ! command -v git &> /dev/null
then
    echo "git could not be found, please install it with: sudo apt install git"
    exit
fi

if ! command -v gemini &> /dev/null
then
    echo "gemini could not be found, please install it with: sudo apt install gemini"
    exit
fi

# Install the script
location="$HOME/.local/bin"
cp juanbot $location/juanbot
chmod +x $location/juanbot

echo "juanbot installed successfully!"
