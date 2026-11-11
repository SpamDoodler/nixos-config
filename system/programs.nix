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
    alacritty
    alsa-utils
    bat
    bottom
    cmake
    curl
    cxxopts
    delta
    eza
    fastfetch
    fd
    feh
    ffmpeg-full
    fmt
    fzf
    gcc
    ghostscript
    git
    git-lfs
    gparted
    gphoto2
    gphoto2fs
    graphviz
    grim # Wayland screenshot utility
    imagemagick
    iw
    jq
    kitty
    libinput
    libtiff
    linux-firmware
    lm_sensors
    ncdu
    neovim
    nmap
    openconnect
    openssl
    p7zip
    pamixer
    paprefs
    pavucontrol
    pciutils
    pkg-config
    powertop
    psmisc
    ripgrep
    rsync
    smartmontools
    starship
    tmux
    trash-cli
    unzip
    uutils-procps
    wget
    wl-clipboard
    zathura
    zgrviewer
    zip
  ];

  environment.variables.EDITOR = "nvim";
}
