{ config, pkgs, ... }:

{
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [ 
    vulkan-tools 
    vulkan-loader 
  ];
}
