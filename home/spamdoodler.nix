{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "spamdoodler";
  home.homeDirectory = "/home/spamdoodler";
  programs.home-manager.enable = true;

  imports = [
    ./alacritty.nix
    ./dropbox.nix
    ./github.nix
    ./ghostty.nix
    ./hyprland/hyprland_hy3.nix
    ./mouse.nix
    #./niri.nix
    ./nvim/nvim.nix
    ./packages.nix
    #./patches.nix
    ./shell.nix
    ./starship.nix
    ./sway/sway.nix
    ./waybar.nix
    ./yazi.nix
    ./xdg.nix
  ];

  home.stateVersion = "23.11";
}
