{ config, pkgs, home-manager, ... }:

{	      
    home.username = "spamdoodler";
	  home.homeDirectory = "/home/spamdoodler";
	  programs.home-manager.enable = true;
    
    imports = [
      ./alacritty.nix
      ./github.nix
      ./nvim/nvim.nix
      ./packages.nix
      ./shell.nix
      ./starship.nix
      ./sway/sway.nix
      ./yazi.nix
    ];
    
	  home.stateVersion = "23.11";
}
