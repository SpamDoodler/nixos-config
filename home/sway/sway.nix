{...}: let
  swayExtraConfig = builtins.readFile ./sway.conf;
in {
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
    extraConfig = swayExtraConfig;
  };
}
