# /etc/nixos/custom-rtw89.nix
{
  config,
  lib,
  ...
}: {
  options = {
    # Define the options for rtw89_pci module
    hardware.enableRtw89Pci = lib.mkEnableOption "Enable rtw89_pci module";

    # Add options to disable_clkreq, disable_aspm_l1, and disable_aspm_l1ss
    hardware.rtw89PciOptions = {
      disable_clkreq = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "Disable clkreq option for rtw89_pci";
      };

      disable_aspm_l1 = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "Disable aspm_l1 option for rtw89_pci";
      };

      disable_aspm_l1ss = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "Disable aspm_l1ss option for rtw89_pci";
      };
    };
  };

  config = lib.mkIf config.hardware.enableRtw89Pci {
    # Add the module to the kernel modules list
    boot.kernelModules = ["rtw89_pci"];

    # Specify module options using boot.kernelParams
    boot.kernelParams = [
      "rtw89_pci.disable_clkreq=${toString config.hardware.rtw89PciOptions.disable_clkreq}"
      "rtw89_pci.disable_aspm_l1=${toString config.hardware.rtw89PciOptions.disable_aspm_l1}"
      "rtw89_pci.disable_aspm_l1ss=${toString config.hardware.rtw89PciOptions.disable_aspm_l1ss}"
    ];
  };
}
