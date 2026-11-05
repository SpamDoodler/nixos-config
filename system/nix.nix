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
      max-jobs = 4;
      cores = 3;
      # cache.nixos.org is very slow from this network; prefer domestic mirrors.
      # NixOS appends cache.nixos.org automatically.
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
    };
  };
}
