{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;
  nix = {
    package = pkgs.nixVersions.git;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      max-jobs = 8;
      download-buffer-size = 524288000;
      substituters = lib.mkDefault [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-24.8.6"
  ];
}
