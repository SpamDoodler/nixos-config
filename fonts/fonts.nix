{ config, pkgs, ... }:

{ 
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
      corefonts
      cascadia-code
      fira-code
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      source-han-sans
      source-han-serif
      source-code-pro
      noto-fonts-emoji
      noto-fonts-extra
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
          "Source Code Pro"
	  "Noto Sans Mono SC"
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
