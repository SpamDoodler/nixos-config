{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    aider-chat
    swaybg
    oh-my-zsh
    google-chrome
    texlive.combined.scheme-full
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
    lie
    rainloop-standard
    pre-commit
    signal-desktop
    ueberzugpp
    imagemagick
    seafile-client
  ];

  programs.firefox.enable = true;
}
