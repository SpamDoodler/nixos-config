{...}: {
  home.username = "spamdoodler";
  home.homeDirectory = "/home/spamdoodler";
  programs.home-manager.enable = true;

  imports = [
    ./alacritty.nix
    ./dropbox.nix
    ./github.nix
    ./ghostty.nix
    ./hyprland/hyprland_hy_lua.nix
    ./mouse.nix
    ./nvim/nvim.nix
    ./opencode/opencode.nix
    ./packages.nix
    ./shell.nix
    ./starship.nix
    ./sway/sway.nix
    ./waybar.nix
    ./yazi.nix
    ./xdg.nix
  ];

  home.stateVersion = "23.11";
}
