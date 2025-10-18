{
  config,
  pkgs,
  ...
}: {
  # Bootloader.
  boot = {
    kernelModules = ["kvm" "kvm_intel" "amdgpu" "kmv_amd"];
    kernelPackages = pkgs.linuxPackages_testing;
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
    kernelParams = [
      "systemd.unified_cgroup_hierarchy=1"
      "amd_pstate=guided"
    ];

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.systemd.enable = true;
    initrd.availableKernelModules = ["amdgpu" "ext4"];

    extraModprobeConfig = ''
      blacklist nouveau
      blacklist floppy
      options nouveau modeset=0
    '';
    blacklistedKernelModules = ["nouvea" "nvidia" "nvidia_drm" "nvidia_modeset"];
    supportedFilesystems = ["ntfs"];

    tmp.cleanOnBoot = true;
  };
}
