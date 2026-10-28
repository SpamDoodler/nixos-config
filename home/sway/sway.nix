{
  lib,
  pkgs,
  ...
}: let
  scripts = import ../desktop-scripts.nix {inherit pkgs;};
  swayExtraConfig = builtins.readFile ./sway.conf;
in {
  systemd.user.services.sway-wallpaper-rotation = {
    Unit = {
      Description = "Sway wallpaper rotation";
      After = ["sway-session.target"];
      PartOf = ["sway-session.target"];
      ConditionEnvironment = ["WAYLAND_DISPLAY" "SWAYSOCK"];
    };
    Service = {
      ExecStart = lib.getExe scripts.swayRotation;
      Restart = "on-failure";
      RestartSec = 3;
      KillMode = "control-group";
    };
    Install.WantedBy = ["sway-session.target"];
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4"; # Super key
      terminal = "alacritty";
      window.border = 0;
      window.commands = [
        {
          command = "border pixel 0";
          criteria = {class = "^.*";};
        }
      ];
      output = {
        "Virtual-1" = {mode = "1920x1080@60Hz";};
      };
      fonts = {
        names = ["Noto Sans CJK SC"];
        style = "Regular";
        size = 10.5;
      };
      bars = [
        {
          command = "waybar -c $HOME/.config/waybar/sway.json";
        }
      ];
    };
    extraConfig =
      builtins.replaceStrings
      ["@waybarToggle@"]
      [(lib.getExe scripts.waybarToggle)]
      swayExtraConfig;
  };
}
