#!/usr/bin/env bash

set -euo pipefail

BAR="${1:-}"
if [[ "$BAR" != "hyprland" && "$BAR" != "sway" ]]; then
    printf 'usage: %s {hyprland|sway}\n' "$0" >&2
    exit 2
fi
CONFIG="$HOME/.config/waybar/${BAR}.json"

# Nix's wrapper changes the process name to .waybar-wrapped.
# Match either exact name, limited to this user's processes.
PROCESS_NAMES='waybar|\.waybar-wrapped'
if pgrep -u "$(id -u)" -x "$PROCESS_NAMES" >/dev/null; then
    # Kill it (clean exit)
    pkill -u "$(id -u)" -x "$PROCESS_NAMES"
else
    # Start it (Home Manager sets PATH etc.)
    waybar -c "$CONFIG" &
fi
