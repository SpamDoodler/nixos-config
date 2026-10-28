# Sandboxed smoke tests: commands are mocked, never connected to a live desktop.
# Run: nix build --no-link --impure --expr 'let f = builtins.getFlake (toString ./.); in import ./tests/desktop-scripts.nix { pkgs = f.nixosConfigurations.NixSama.pkgs; }'
{pkgs}: let
  mockCommand = pkgs.writeShellScript "desktop-mock-command" ''
    command="''${0##*/}"
    printf '%s\n' "$command $*" >> "$MOCK_LOG"
    case "$command" in
      pgrep) [ "$MOCK_BAR_RUNNING" = 1 ] ;;
      sleep)
        # Stop each infinite rotator after its first normal sleep, without
        # changing the production loop or waiting in real time.
        if [ "$1" = 30 ]; then kill -TERM "$PPID"; fi
        ;;
    esac
  '';
  mocks = pkgs.runCommand "desktop-script-mocks" {} ''
    mkdir -p "$out/bin"
    for command in hyprctl swaymsg sleep pgrep pkill waybar; do
      ln -s ${mockCommand} "$out/bin/$command"
    done
  '';
  scripts = import ../home/desktop-scripts.nix {
    pkgs =
      pkgs
      // {
        writeShellApplication = args:
          pkgs.writeShellApplication (args // {runtimeInputs = [mocks] ++ args.runtimeInputs;});
      };
  };
in
  pkgs.runCommand "desktop-script-tests" {
    nativeBuildInputs = [pkgs.python3];
    HYPR_ROTATION = "${scripts.hyprlandRotation}/bin/desktop-hyprland-wallpapers";
    SWAY_ROTATION = "${scripts.swayRotation}/bin/desktop-sway-wallpapers";
    WALLPAPER_TOGGLE = "${scripts.wallpaperToggle}/bin/desktop-wallpaper-toggle";
    WAYBAR_TOGGLE = "${scripts.waybarToggle}/bin/desktop-waybar-toggle";
  } ''
    python3 - <<'PY'
    import os
    import signal
    import subprocess
    import tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory(prefix="desktop tests ") as temporary:
        home = Path(temporary)
        log = home / "commands.log"
        sfw = home / "Pictures/anime_wallpapers/sfw"
        nsfw = home / "Pictures/anime_wallpapers/nsfw"
        sway = home / "Pictures/Wallpapers"
        for folder in (sfw, nsfw, sway):
            folder.mkdir(parents=True)
            (folder / "image.jpg").touch()
        env = os.environ | {
            "HOME": str(home), "MOCK_LOG": str(log), "MOCK_BAR_RUNNING": "0",
        }

        def run(key, *args, expected=0, extra_env=None):
            log.write_text("")
            result = subprocess.run(
                [os.environ[key], *args], env=env | (extra_env or {}),
                capture_output=True, text=True, timeout=5,
            )
            assert result.returncode == expected, (key, result.returncode, result.stderr)
            return log.read_text().splitlines(), result

        commands, _ = run("HYPR_ROTATION", expected=-signal.SIGTERM)
        assert commands == [
            "sleep 1", "hyprctl hyprpaper unload all",
            f"hyprctl hyprpaper preload {sfw}/image.jpg",
            f"hyprctl hyprpaper wallpaper eDP-1,{sfw}/image.jpg", "sleep 30",
        ], commands
        state = home / ".cache/current_wallpaperset"
        assert state.read_text().strip() == str(sfw)

        for folder in (nsfw, sfw):
            commands, _ = run("WALLPAPER_TOGGLE")
            assert state.read_text().strip() == str(folder)
            assert commands == [
                f"hyprctl hyprpaper preload {folder}/image.jpg",
                f"hyprctl hyprpaper wallpaper eDP-1,{folder}/image.jpg",
            ], commands

        commands, _ = run("SWAY_ROTATION", expected=-signal.SIGTERM)
        assert commands == [f"swaymsg output '*' bg {sway}/image.jpg fill", "sleep 30"], commands

        for compositor in ("hyprland", "sway"):
            commands, _ = run("WAYBAR_TOGGLE", compositor)
            assert commands == [
                "pgrep -x waybar", f"waybar -c {home}/.config/waybar/{compositor}.json",
            ], commands
            commands, _ = run("WAYBAR_TOGGLE", compositor, extra_env={"MOCK_BAR_RUNNING": "1"})
            assert commands == ["pgrep -x waybar", "pkill -x waybar"], commands

        for args in ((), ("invalid",)):
            commands, result = run("WAYBAR_TOGGLE", *args, expected=2)
            assert not commands and "usage:" in result.stderr
    print("desktop script smoke tests passed")
    PY
    touch "$out"
  ''
