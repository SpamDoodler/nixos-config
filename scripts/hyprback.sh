#!/usr/bin/env bash
STATE_FILE="$HOME/.cache/current_wallpaperset"
SFW_DIR="$HOME/Pictures/anime_wallpapers/sfw"

mkdir -p "$(dirname "$STATE_FILE")"
[ -f "$STATE_FILE" ] || echo "$SFW_DIR" > "$STATE_FILE"

while true; do
    WALLPAPER_DIR=$(cat "$STATE_FILE")
    # Choose a random regular file; repeats are possible.
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)
    sleep 1
    # Apply the selected wallpaper
    hyprctl hyprpaper unload all || true
    hyprctl hyprpaper preload "$WALLPAPER"
    hyprctl hyprpaper wallpaper "eDP-1,$WALLPAPER"

    sleep 30
done
