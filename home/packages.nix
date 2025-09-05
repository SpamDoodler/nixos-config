{config, pkgs, ...}:

{
    home.packages = with pkgs; [
      swaybg
      oh-my-zsh
      google-chrome
      texlive.combined.scheme-full
      mpv
      ani-cli
      nodePackages_latest.peerflix
      osu-lazer-bin
      inkscape
      rawtherapee
      libreoffice-qt
      hunspell
      hunspellDicts.en-us
      tor-browser
      gap-full
      lie
      rainloop-standard
      pre-commit
	  ];
}
