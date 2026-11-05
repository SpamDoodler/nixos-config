# Wallpapers

Priority: **P2**. The current system works, but it is hard-coded to one
monitor, rotates every 30 seconds, and stores state in a directory that is
allowed to be deleted.

## Current state

| Item | Current | File |
|---|---|---|
| Hyprland rotation | `hyprback.sh`, infinite loop, 30 s sleep | `scripts/hyprback.sh` |
| Hyprland toggle | `set_wallpapers.sh`, switches SFW/NSFW folder | `scripts/set_wallpapers.sh` |
| Sway rotation | `wallpapers.sh`, infinite loop, 30 s sleep | `scripts/wallpapers.sh` |
| State | `~/.cache/current_wallpaperset` | scripts |
| Hyprpaper | enabled, empty settings, systemd target `hyprland-session.target` | `home/hyprland/hyprland_hy_lua.nix:29-35` |
| Rotation unit | user service, `PartOf`/`Requires` hyprpaper, restart on failure | `home/hyprland/hyprland_hy_lua.nix:37-50` |
| Wrapper | `writeShellApplication` with `bashOptions = []` | `home/desktop-scripts.nix:3-15` |
| Tests | mocked `hyprctl`/`swaymsg`, asserts current commands | `tests/desktop-scripts.nix` |
| Outputs | only `eDP-1` today; HDMI is `HDMI-A-1` when connected | live system |
| Toggle binding | `SUPER + SHIFT + B` in Hyprland | `bindings-and-startup.lua:65` |

Wallpaper directories are `~/Pictures/anime_wallpapers/{sfw,nsfw}`. The
default wallpaper path in the inactive fallback config is
`~/Pictures/anime_wallpapers/sfw/default.jpeg`.

## Bugs and design problems

1. **One output only.** `hyprback.sh:16` and `set_wallpapers.sh:22` hard-code
   `eDP-1`. Plugging in HDMI leaves the new output black until something else
   sets it.
2. **Black flash on every change.** `hyprback.sh:14-16` runs
   `unload all` before `preload` and `wallpaper`. Hyprpaper briefly has no
   texture. Preload the new image, set it, then unload only the previous
   image.
3. **`find` is not image-aware.** `hyprback.sh:11` selects any regular file.
   A `.txt`, `.webp` that hyprpaper rejects, or an empty directory breaks the
   loop. It also splits names on whitespace and newlines.
4. **Sway `find` precedence bug.** `wallpapers.sh:8`:
   `find dir -type f -name '*.jpg' -o -name '*.png' -o -name '*.jpeg'`.
   `-type f` only applies to the first branch; a directory named `foo.png`
   can be selected. Add parentheses around the name tests.
5. **No empty-state handling.** `set_wallpapers.sh:9` runs `cat` on a missing
   state file. `hyprback.sh` creates it, but the toggle may run first after a
   cache wipe.
6. **State belongs in `$XDG_STATE_HOME`.** `~/.cache` may be deleted by
   cleaners. Use `${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/` and keep
   the old path as a one-time fallback.
7. **30-second rotation is aggressive.** It redraws the GPU-backed background,
   wakes the compositor, and makes screenshots/recordings unpredictable. If
   the fast rotation is intentional, keep it, but make the interval a single
   variable and consider 5–30 minutes for daily use.
8. **The loop hides failures.** `hyprctl` errors are ignored (except
   `unload all`). If hyprpaper is not ready, the loop silently applies nothing
   until the next tick.
9. **The systemd unit is an infinite loop.** `Restart=on-failure` is useful,
   but a oneshot service plus a timer is easier to observe, test, and stop.
   The current test kills the loop after `sleep 30`.
10. **No monitor-hotplug handling.** Even with multiple outputs, a new monitor
    is only painted on the next tick. A timer-driven `apply-all` is simpler
    than listening to Hyprland events.
11. **Inactive fallback duplicates settings.** `hyprland.nix` and
    `hyprland_hy3.nix` each configure hyprpaper and point at `default.jpeg`.
    Keep one fallback path; do not let three configs drift.

## Target design

### One script, explicit subcommands

Replace the two Hyprland scripts with one `wallpaper` command:

```text
wallpaper next                 # choose a random image from the active set
wallpaper set <dir>            # switch set and apply one image
wallpaper toggle               # switch between configured sets
wallpaper apply <file>         # apply a specific image to every output
wallpaper apply-all            # reapply the current image to all outputs
```

Keep the Sway script separate until Sway is tested. A single script removes
the duplicated state parsing and makes the toggle reuse the same apply code.

### Robust selection

```bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
state_file="$state_dir/current-set"
mkdir -p "$state_dir"

mapfile -d '' images < <(
  find "$dir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' \) -print0
)
(( ${#images[@]} > 0 )) || { echo "no images in $dir" >&2; exit 0; }
image="${images[RANDOM % ${#images[@]}]}"
```

`RANDOM` avoids the `shuf` dependency and avoids selecting the same image
twice in a row if you track the previous path. If you prefer `shuf`:
`mapfile -d '' images < <(find ... -print0 | shuf -z -n 1)`.

### Apply to every output

```bash
apply() {
  local image="$1" monitor
  hyprctl hyprpaper preload "$image" >/dev/null
  while IFS= read -r monitor; do
    hyprctl hyprpaper wallpaper "$monitor,$image" >/dev/null
  done < <(hyprctl monitors -j | jq -r '.[].name')
  # Unload the previous image only after the new one is visible.
  [[ -n "${previous:-}" && "$previous" != "$image" ]] && \
    hyprctl hyprpaper unload "$previous" >/dev/null 2>&1 || true
  previous="$image"
}
```

If you want a different image per output, keep a state file per monitor and
loop. For a laptop with one internal panel and one HDMI display, the same
image on both is less surprising.

Do not use `hyprctl hyprpaper unload all` on every tick. It is the cause of
the flash. `hyprctl hyprpaper listloaded` is the verification command.

### Timer instead of a loop

Recommended user units:

```nix
systemd.user.services.hyprland-wallpaper = {
  Unit = {
    Description = "Apply a random Hyprland wallpaper";
    After = ["hyprland-session.target" "hyprpaper.service"];
    PartOf = ["hyprland-session.target"];
    Requires = ["hyprpaper.service"];
    ConditionEnvironment = ["WAYLAND_DISPLAY" "HYPRLAND_INSTANCE_SIGNATURE"];
  };
  Service = {
    Type = "oneshot";
    ExecStart = "${scripts.wallpaper}/bin/wallpaper next";
  };
};

systemd.user.timers.hyprland-wallpaper = {
  Unit.Description = "Rotate the Hyprland wallpaper";
  Timer = {
    OnStartupSec = "30s";
    OnUnitActiveSec = "15min";
    AccuracySec = "1min";
    Persistent = false;
  };
  Install.WantedBy = ["hyprland-session.target"];
};
```

`OnStartupSec` paints the first wallpaper after login; `OnUnitActiveSec`
handles later rotations. `Persistent = false` is correct: do not replay
missed rotations after a reboot. If you keep the 30-second interval, use
`OnUnitActiveSec = "30s"` and expect more wakeups; measure with `powertop`.

The service must not depend on the toggle. The toggle only rewrites the state
file and applies one image; the next timer tick reads the new state.

### Hyprpaper vs alternatives (answer)

| Option | Language | Fit | Verdict |
|---|---|---|---|
| **hyprpaper** | C++ | Official Hyprland wallpaper daemon, IPC, per-output still images | **Keep** for still images |
| **awww** (formerly `swww`) | Rust | Animated wallpapers, transitions, its own daemon/socket | Credible if you want animation/transitions; not clearly better for stills |
| **wpaperd** | Rust | General wlroots daemon | **Not recommended**: upstream notes Hyprland does not behave like other compositors and has multi-monitor issues |
| **swaybg** | C | Simple wlroots background | Sway fallback only; no runtime IPC |
| **hyprpaper via `services.hyprpaper`** | C++ | Home Manager module, systemd integration | Current choice; keep |

Answer to “replace Hyprpaper only if Rust alternatives are genuinely better”:
**no, not for your current use case.** `awww` is genuinely good and actively
maintained, but it adds a second daemon and a different IPC surface for a
feature you do not need (animated transitions). Revisit `awww` only if you
want cross-fades or animated wallpapers. Do not migrate just because it is
written in Rust.

### Defaults and state

- Default set: `~/Pictures/anime_wallpapers/sfw`.
- Alternate set: `~/Pictures/anime_wallpapers/nsfw`.
- If the state file is missing or points to an empty directory, fall back to
  the default set, then to the first image found anywhere under
  `~/Pictures/anime_wallpapers`.
- Do not store an image path in the Nix store; paths under `$HOME` are fine.
- Keep a neutral `wallpapers/favorites` set for screen sharing and
  screenshots. The current SFW/NSFW toggle is easy to trigger accidentally
  while sharing a screen.
- If you use Hyprlock, give it its own background path; do not couple the
  lock screen to the rotating set.

### Sway (deferred)

Do not change `scripts/wallpapers.sh` or `home/sway/sway.nix` until the
`Virtual-1` issue is tested separately. When you do:

- fix the `find` parentheses and use `-print0`;
- use `swaymsg output '*' bg "$image" fill`;
- add `ConditionEnvironment = ["SWAYSOCK"]` (already present);
- decide whether Sway should share the same state file (it currently uses a
  different directory, `~/Pictures/Wallpapers`).

## Tasks

- [ ] Fix `find` selection to images only, with `-print0`, in both Hyprland
      scripts.
- [ ] Replace hard-coded `eDP-1` with all monitors from
      `hyprctl monitors -j`.
- [ ] Stop calling `unload all` before applying; unload the previous image
      after the new one is set.
- [ ] Move state to `${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/`.
- [ ] Make the rotation interval a single variable; choose 30 s or 15 min.
- [ ] Decide timer vs loop; if timer, add the units above.
- [ ] Create a neutral `favorites` set for screen sharing (optional).
- [ ] Update `tests/desktop-scripts.nix` for the new commands and state path.
- [ ] Test with an empty directory, a filename containing spaces, and no
      state file.
- [ ] Test HDMI hotplug with `eDP-1` + `HDMI-A-1`.
- [ ] Leave Sway untouched until its own test.

## Verification

```sh
systemctl --user status hyprpaper hyprland-wallpaper.timer
hyprctl hyprpaper listloaded
hyprctl monitors -j | jq -r '.[].name'
~/.local/state/wallpaper/current-set
journalctl --user -u hyprland-wallpaper -n 50 --no-pager
```

Manual checks:

1. Delete the state file; run `wallpaper next`; it should choose the default
   set and not crash.
2. Create a filename with spaces; run again; it should still load.
3. Connect HDMI; run `wallpaper apply-all`; both outputs should change.
4. Toggle sets; confirm the next tick keeps the new set.
5. Suspend/resume; confirm the wallpaper is still present (hyprpaper may need
   a reapply after resume; if so, add `wallpaper apply-all` to a resume hook).

## Open questions

- Is 30-second rotation intentional, or would 15 minutes be better?
- Same image on all outputs, or one per monitor?
- Keep the SFW/NSFW split, or replace it with neutral set names?
- Do you want animated/transition wallpapers enough to justify `awww`?
- Should Hyprlock use the current wallpaper or a fixed image?