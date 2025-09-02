!/usr/bin/env bash

# Check if Waybar is running
if pgrep waybar >/dev/null; then
    # Kill it (clean exit)
    pkill waybar
else
    # Start it (Home Manager sets PATH etc.)
    waybar &
fi

