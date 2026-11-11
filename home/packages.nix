{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    ani-cli
    dosbox-staging
    gap-full
    google-chrome
    hunspell
    hunspellDicts.en-us
    imagemagick
    inkscape
    libreoffice-qt
    lie
    lilypond
    mpv
    oh-my-zsh
    osu-lazer-bin
    peerflix-server
    pre-commit
    privoxy
    rawtherapee
    signal-desktop
    supercollider
    swaybg
    tdf
    texliveFull
    tor-browser
    ueberzugpp
    zoom-us
  ];

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };
}
