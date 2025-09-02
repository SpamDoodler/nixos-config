{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./custom-rtw89.nix # Patching Rtw89 Issue
    ./video.nix
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.enableRtw89Pci = true;

  # Configure console keymap
  console.keyMap = "us-acentos";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
