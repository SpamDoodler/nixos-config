{ config, pkgs,... }:

{
  users.users.spamdoodler = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "spamdoodler";
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "audio" 
      "video" 
      "dialout"
      "libvirtd" 
      "docker" 
      "gamemode"];
    uid = 1000;
    packages = with pkgs; [];
  };

}
