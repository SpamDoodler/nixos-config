{
  config,
  pkgs,
  ...
}: {
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        "Term" = "xterm-256color";
      };
      window = {
        padding.x = 10;
        padding.y = 10;
      };
      font = {
        size = 11;

        normal.family = "FiraCode Nerd Font";
        normal.style = "Medium";
        bold.family = "FiraCode Nerd Font";
        italic.family = "FiraCode Nerd Font";
      };
      colors = {
        primary = {
          background = "0x11212d";
          foreground = "0xcbe3e7";
        };

        # Normal colors
        normal = {
          black = "0x000e23";
          red = "0xef3030";
          green = "0x95ffa4";
          yellow = "0xffe9aa";
          blue = "0x91ddff";
          magenta = "0xc991e1";
          cyan = "0xaaffe4";
          white = "0xcbe3e7";
        };

        # Bright colors
        bright = {
          black = "0x565575";
          red = "0xff7458";
          green = "0x7fff00";
          yellow = "0xffb378";
          blue = "0x65b2ff";
          magenta = "0x906cff";
          cyan = "0x63f2f1";
          white = "0xa6b3cc";
        };
      };
      cursor.style = "Beam";
    };
  };
}
