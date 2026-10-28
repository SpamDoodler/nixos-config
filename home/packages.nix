{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    swaybg
    oh-my-zsh
    dosbox-staging
    google-chrome
    texliveFull
    mpv
    ani-cli
    peerflix-server
    osu-lazer-bin
    inkscape
    rawtherapee
    libreoffice-qt
    hunspell
    hunspellDicts.en-us
    tor-browser
    tdf
    gap-full
    supercollider
    lilypond
    lie
    rainloop-standard
    pre-commit
    signal-desktop
    ueberzugpp
    imagemagick
    zoom-us
  ];

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };
}
