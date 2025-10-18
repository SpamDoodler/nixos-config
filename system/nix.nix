{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;
  programs.ccache.enable = true;
  nix = {
    package = pkgs.nixVersions.git;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      max-jobs = 8;
      download-buffer-size = 524288000;
      substituters = lib.mkDefault [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
      extra-sandbox-paths = ["/var/cache/ccache"];
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-24.8.6"
  ];
}
