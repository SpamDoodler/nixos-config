{
  config,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "hyprland/workspaces"
        ];
        modules-center = ["clock"];
        modules-right = ["pulseaudio" "cpu" "memory" "disk" "temperature" "battery" "network" "tray"];

        "disk" = {
          interval = 30;
          format = " 🖴 {free} ";
        };

        "network" = {
          format-wifi = "   {essid} {signalStrength}% ";
          format-ethernet = " 🖧 {ifname} ";
          format-disconnected = "  offline ";
          tooltip = true;
          interval = 5;
        };
        "memory" = {
          format = " {used:0.1f}G/{total:0.1f}G ";
          interval = 5;
        };
        "clock" = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          interval = 1;
        };
        "pulseaudio" = {
          format = " 🔈 {volume}% ";
          format-muted = " 🔇 ";
        };
        "cpu" = {format = "  {usage}% ";};
        "temperature" = {
          thermal-zone = 0;
          format = " {temperatureC}°C ";
        };
        "battery" = {format = "  {capacity}% ";};
      };
    };
    style = ''
      * {
        border: none;
        font-family: "Iosevka Nerd Font";
        font-size: 14px;
      }
      window#waybar {
        background: rgba(40, 44, 72, 0.9);
        color: #eceff4;
      }
      #workspaces button.current_output.visible {
        background-color: #89b4fa;
        color: #1e1e2e;
        font-weight: bold;
      }

      #workspaces button.active {
        background-color: #6994da;
        color: #1e1e2e;
        font-weight: bold;
      }

      #workspaces button {
        padding: 0px 3px;
        background-color: #32348a;
        border-radius: 0px;
        color: #1e1e2e;
      }
    '';
  };
}
