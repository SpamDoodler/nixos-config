{ config, pkgs, ... }:

{ 
  nixpkgs.config.allowUnfree = true;

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
    git
    delta
    grim # Wayland screenshot utility
    alacritty
    ripgrep
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
    fzf
    libinput
    trash-cli
    alsa-utils
    gparted
    gphoto2
    gphoto2fs
    libtiff
    ncdu
    openconnect
    openssl
    graphviz
    zgrviewer
    ghostscript
    smartmontools
    wl-clipboard
    zip
    imagemagick
  ];
  
  environment.variables.EDITOR = "nvim";

  # TODO: zsh integration and alias for bat, eza, fzf, etc.

}
