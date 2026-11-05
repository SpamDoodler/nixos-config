{...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;

      background = [
        {
          monitor = "";
          color = "rgba(0,0,0,0.85)";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "Password";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 64;
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    # Lock only in Hyprland, not in the Sway fallback.
    systemdTarget = "hyprland-session.target";
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  services.hyprpolkitagent.enable = true;
  services.mako.enable = true;
}
