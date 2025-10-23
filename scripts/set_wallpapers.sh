#!/usr/bin/env bash


# Where your wallpaper folders are
SFW_DIR="$HOME/Pictures/anime_wallpapers/sfw"
NSFW_DIR="$HOME/Pictures/anime_wallpapers/nsfw"
STATE_FILE="$HOME/.cache/current_wallpaperset"

CURRENT=$(cat "$STATE_FILE")

if [ "$CURRENT" = "$SFW_DIR" ]; then
    echo "$NSFW_DIR"> "$STATE_FILE"
    FOLDER="$NSWF_DIR"
else
    echo "$SFW_DIR" > "$STATE_FILE"
    FOLDER="$SFW_DIR"
fi

WALLPAPER=$(find "$FOLDER" -type f | shuf -n 1)

pkill hyprpaper
hyprpaper
# Apply the selected wallpaper
# hyprctl hyprpaper unload all || true
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper "eDP-1,$WALLPAPER"
