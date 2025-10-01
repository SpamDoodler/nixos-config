{ config, pkgs, ...}:

{
 # Virtualisation
  virtualisation = { 
    libvirtd.enable = true;
    docker = {
      enable = true;
      enableNvidia = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    enableNvidia = true;
    dockerCompat = false;
  };

  environment.systemPackages = [ pkgs.distrobox ];
}
