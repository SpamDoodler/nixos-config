{ config, pkgs, ... }:

let
  swayExtraConfig = builtins.readFile ./sway.conf;
in
{
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";  # Super key
      terminal = "alacritty";
      window.border = 0;
      window.commands = [
        {
          command="border pixel 0";
          criteria = {class="^.*";};
        }
      ];
      output = {
        "Virtual-1" = { mode = "1920x1080@60Hz"; };
      };
      fonts = {
        names = ["Pango Hack"];
        style = "Regular";
        size = 11.0;
      };
      bars = [{
        command = "waybar";
      }];
    };
    extraConfig = swayExtraConfig;
  };
  
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "clock" ];
        modules-right = ["pulseaudio" "cpu" "memory" "disk" "temperature" "battery"  "network" "tray" ];

        "disk" = {
          interval = 30;
          format = " 🖴 {free} ";
        };
        
        "network" = {
          format-wifi = 
              "   {essid} {signalStrength}% ";
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
          format = " 🔈 {volume}% " ;
          format-muted = " 🔇 ";
        };
        "cpu" = { format = "  {usage}% "; };
        "temperature" = {
          thermal-zone = 0;
          format = " {temperatureC}°C ";
        };
        "battery" = { format = "  {capacity}% "; };
      };
    };
    style = ''
      * {
        border: none;
        font-family: "Iosevka Nerd Font";
        font-size: 12px;
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

      #workspaces button {
        background-color: #32348a;
        color: #1e1e2e;
      }
    '';
  };
}
