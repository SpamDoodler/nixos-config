{
  config,
  pkgs,
  ...
}: {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
      sarasa-gothic
      corefonts
      cascadia-code
      fira-code
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      source-han-sans
      source-han-serif
      source-code-pro
      noto-fonts-color-emoji
      noto-fonts
      pango
      hack-font
      jetbrains-mono
      lmodern
      lmmath
      (pkgs.stdenv.mkDerivation {
        name = "BrownPro";
        src = ./BrownPro;
        installPhase = ''
                 mkdir -p $out/share/fonts
          cp -r $src/*.ttf $out/share/fonts/
        '';
      })
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [
          "Sarasa Mono SC"
          "Noto Sans Mono CJK SC"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "Source Code Pro"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Code Pro"
        ];
      };
    };
  };
}
