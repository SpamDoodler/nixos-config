#!/bin/bash

# Directory containing your wallpaper images
wallpaper_dir="$HOME/Pictures/Wallpapers"

while true; do
    # Get a random image from the wallpaper directory
    random_image=$(find "$wallpaper_dir" -type f -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' | shuf -n 1)
    # echo "Setting wallpaper to: $random_image"
    # Set the random image as the wallpaper using feh
    swaymsg "output '*' bg $random_image fill"

    # Sleep for 5 minutes (300 seconds) before changing the wallpaper again
    sleep 30
done

