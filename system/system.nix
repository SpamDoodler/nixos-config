{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./boot.nix
    ./environment.nix
    ./networking.nix
    ./nix.nix
    ./locals.nix
    ./patches.nix
    ./powerManagement.nix
    ./programs.nix
    ./services.nix
    ./systemd.nix
    ./virtualisation.nix
  ];

  # Set your time zone.
  services.automatic-timezoned.enable = true;
  # time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.05"; # Did you read the comment?
}
