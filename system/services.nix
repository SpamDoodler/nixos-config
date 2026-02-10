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

  services.journald.extraConfig = ''
    Storage=volatile
    RateLimitInterval=30s
    RateLimitBurst=1000
  '';

  services.tor = {
    enable = true;

    # Disable GeoIP to prevent the Tor client from estimating the locations of Tor nodes it connects to
    enableGeoIP = false;

    # Enable Torsocks for transparent proxying of applications through Tor
    torsocks.enable = true;

    # Enable the Tor client
    client = {
      enable = true;
    };

    # Enable and configure the Tor relay
    relay.enable = false;

    # Configure Tor settings
    settings = {
      Nickname = "SpamDoodler";
      ContactInfo = "doodler.spammail@gmail.com";

      # Bandwidth settings
      MaxAdvertisedBandwidth = "100 MB";
      BandWidthRate = "50 MB";
      RelayBandwidthRate = "50 MB";
      RelayBandwidthBurst = "100 MB";

      # Restrict exit nodes to a specific country (use the appropriate country code)
      ExitNodes = "{ch} StrictNodes 1";

      # Reject all exit traffic
      ExitPolicy = ["reject *:*"];

      # Performance and security settings
      CookieAuthentication = true;
      AvoidDiskWrites = 1;
      HardwareAccel = 1;
      SafeLogging = 1;
      NumCPUs = 3;

      # Network settings
      ORPort = [443];
    };
  };

  # Operating a Snowflake proxy helps others circumvent censorship. Safe to run.
  services.snowflake-proxy = {
    enable = true;
    capacity = 10;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
  };

  # Wayland related
  security.polkit.enable = true;
  programs.light.enable = true;

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
