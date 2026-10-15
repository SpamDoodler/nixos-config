#!/bin/bash

# Directory containing your wallpaper images
wallpaper_dir="$HOME/Pictures/Wallpapers"

while true; do
    # Get a random image from the wallpaper directory
    random_image=$(find "$wallpaper_dir" -type f -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' | shuf -n 1)
    # Set the random image as the Sway wallpaper.
    swaymsg "output '*' bg $random_image fill"

    # Wait 30 seconds before choosing again.
    sleep 30
done
