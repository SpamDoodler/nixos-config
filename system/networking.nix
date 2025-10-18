{
  config,
  pkgs,
  ...
}: {
  networking = {
    hostName = "NixSama"; # Define your hostname.

    # TODO: Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking

    # networking.wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi = {
        scanRandMacAddress = false;
      };
      # wifi.backend = "iwd";
      wifi.powersave = false;
    };
    interfaces.wlan0.useDHCP = true;
    nameservers = ["8.8.8.8"];

    nftables.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [22 443 51820];
      allowedUDPPorts = [51820];
    };
  };
}
