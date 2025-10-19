#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/anime_wallpapers/"

while true; do
    # Get a random wallpaper that is not the current one
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

    # Apply the selected wallpaper
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$WALLPAPER"
    hyprctl hyprpaper wallpaper "eDP-1,$WALLPAPER"

    sleep 30
done
