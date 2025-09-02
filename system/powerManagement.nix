{ config, pkgs, ... }:

{
  # Power settings
  services.power-profiles-daemon.enable = false;
  services.thermald.enable = true;
  services.upower  = {
    enable = true;
    usePercentageForPolicy = true;
  };
  services.tlp = 
  {
    enable = false;
    # settings = {
    #  CPU_BOOST_ON_AC = 1;
    #  CPU_BOOST_ON_BAT = 0;
    #  CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #  CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    #  CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    #  CPU_ENERGY_PERF_POLICY_ON_AC = "performance"; 
    # };
  };

  services.auto-cpufreq.enable = true;

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "schedutil";
  };

  services.system76-scheduler.enable = true;
}
