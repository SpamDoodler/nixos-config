# Shared store-backed commands; picture collections and state remain in $HOME.
{pkgs}: let
  packageScript = name: runtimeInputs: source:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      # Preserve each script's existing error handling. In particular, the
      # wallpaper loops retry rather than exiting on individual command errors.
      bashOptions = [];
      text = builtins.readFile source;
    };
in {
  hyprlandRotation = packageScript "desktop-hyprland-wallpapers" [pkgs.coreutils pkgs.findutils pkgs.hyprland] ../scripts/hyprback.sh;
  swayRotation = packageScript "desktop-sway-wallpapers" [pkgs.coreutils pkgs.findutils pkgs.sway] ../scripts/wallpapers.sh;
  wallpaperToggle = packageScript "desktop-wallpaper-toggle" [pkgs.coreutils pkgs.findutils pkgs.hyprland] ../scripts/set_wallpapers.sh;
  waybarToggle = packageScript "desktop-waybar-toggle" [pkgs.procps pkgs.waybar] ../scripts/waybar.sh;
}
