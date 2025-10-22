{
  config,
  lib,
  pkgs,
  hyprland,
  ...
}: {
  systemd = {
    settings.Manager = {
      DefaultLimitNOFILE = "1048576";
      DefaultLimitNPROC = "65535";
      DefaultTasksMax = "49152";
    };

    services.sshd.serviceConfig = {
      TimeoutStartSec = "15s";
      TimeoutStopSec = "10s";
    };

    oomd.enable = true;
  };
}
