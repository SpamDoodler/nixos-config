{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  # Use the same nixos-unstable package set as Home Manager and Mesa.
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Explicitly select the Home Manager Lua entrypoint for graphical logins.
  environment.sessionVariables = {
    HYPRLAND_CONFIG = "/home/spamdoodler/.config/hypr/hyprland.lua";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    unzip
    p7zip
    eza
    starship
    ripgrep
    git
    fd
    fmt
    git-lfs
    jq
    delta
    grim # Wayland screenshot utility
    alacritty
    kitty
    bottom
    powertop
    neovim
    zathura
    wget
    curl
    fastfetch
    pamixer
    paprefs
    pavucontrol
    pciutils
    iw
    linux-firmware
    nmap
    rsync
    ffmpeg-full
    lm_sensors
    feh
    gcc
    cmake
    cxxopts
    pkg-config
    fzf
    libinput
    trash-cli
    alsa-utils
    gparted
    gphoto2
    gphoto2fs
    libtiff
    ncdu
    bat
    openconnect
    openssl
    graphviz
    zgrviewer
    ghostscript
    smartmontools
    wl-clipboard
    zip
    imagemagick
    uutils-procps
    psmisc
    tmux
  ];

  environment.variables.EDITOR = "nvim";
}
