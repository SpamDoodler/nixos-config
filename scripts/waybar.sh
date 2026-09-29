#!/usr/bin/env bash

set -euo pipefail

BAR="${1:-}"
if [[ "$BAR" != "hyprland" && "$BAR" != "sway" ]]; then
    printf 'usage: %s {hyprland|sway}\n' "$0" >&2
    exit 2
fi
CONFIG="$HOME/.config/waybar/${BAR}.json"

# Check if Waybar is running
if pgrep waybar >/dev/null; then
    # Kill it (clean exit)
    pkill waybar
else
    # Start it (Home Manager sets PATH etc.)
    waybar -c "$CONFIG" &
fi
