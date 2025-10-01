{ config, pkgs, ... }:

{
  imports = [
    ./nix.nix
    ./boot.nix
    ./networking.nix
    ./locals.nix
    ./powerManagement.nix
    ./programs.nix
    ./services.nix
    ./systemd.nix
    ./virtualisation.nix
  ];
  
  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.05"; # Did you read the comment?
}
