{ config, pkgs, ... }:

{
  imports = [
    ./nix.nix
    ./boot.nix
    ./networking.nix
    ./powerManagement.nix
    ./programs.nix
    ./services.nix
    ./systemd.nix
    ./locals.nix
  ];
  
  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.05"; # Did you read the comment?
}
