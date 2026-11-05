{
  config,
  pkgs,
  ...
}: {
  # Gamemode
  programs.gamemode.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable printing
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [gutenprint];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing.browsing = true;
  services.printing.browsedConf = ''
    BrowseDNSSDSubTypes _cups,_print
    BrowseLocalProtocols all
    BrowseRemoteProtocols all
    CreateIPPPrinterQueues All
    BrowseProtocols all
  '';

  services.journald.settings.Journal = {
    Storage = "persistent";
    SystemMaxUse = "1G";
    RateLimitInterval = "30s";
    RateLimitBurst = 1000;
  };

  # Enable the OpenSSH daemon. Key-only access for the local user.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["spamdoodler"];
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };

  services.fwupd.enable = true;
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  services.xserver.enable = false;

  # TODO: Grafana Monitoring Tool.

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Wayland related
  security.polkit.enable = true;
  security.pam.services.hyprlock = {};

  services.resolved = {
    enable = false;
    settings.Resolve = {
      DNSSEC = "true";
      Domains = ["~."];
      FallbackDNS = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];
      DNSoverTLS = "true";
    };
  };
}
