#!/usr/bin/env bash
STATE_FILE="$HOME/.cache/current_wallpaperset"
SFW_DIR="$HOME/Pictures/anime_wallpapers/sfw"
[ -f "$STATE_FILE" ] || echo "sfw" > "$STATE_FILE"

while true; do
    WALLPAPER_DIR=$(cat "$STATE_FILE")
    # Get a random wallpaper that is not the current one
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)
    sleep 1
    # pkill hyprpaper
    # hyprpaper
    # Apply the selected wallpaper
    # hyprctl hyprpaper unload all
    hyprctl hyprpaper unload all || true
    hyprctl hyprpaper preload "$WALLPAPER"
    hyprctl hyprpaper wallpaper "eDP-1,$WALLPAPER"

    sleep 30
done
