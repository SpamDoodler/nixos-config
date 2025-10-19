{
  config,
  pkgs,
  ...
}: let
  swayExtraConfig = builtins.readFile ./sway.conf;
in {
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
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
        names = ["Pango Hack"];
        style = "Regular";
        size = 11.0;
      };
      bars = [
        {
          command = "waybar";
        }
      ];
    };
    extraConfig = swayExtraConfig;
  };
}
