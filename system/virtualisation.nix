{
  config,
  pkgs,
  ...
}: {
  # Virtualisation
  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  environment.systemPackages = [pkgs.distrobox];
}
