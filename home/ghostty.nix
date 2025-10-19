{
  config,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;

    settings = {
      font-family = "FiraCode Nerd Font";
      font-size = 12;
    };
  };
}
