{
  config,
  pkgs,
  ...
}: 

{
  home.packages = with pkgs; [
    hyprpaper
    wofi
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];
    plugins = [pkgs.hyprlandPlugins.hy3];
    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod SHIFT, Q, killactive"

        # Move focus
        "$mod, LEFT, movefocus, l"
        "$mod, DOWN, movefocus, d"
        "$mod, UP, movefocus, u"
        "$mod, RIGHT, movefocus, r"

        # Move window
        "$mod SHIFT, LEFT, movewindow, l"
        "$mod SHIFT, DOWN, movewindow, d"
        "$mod SHIFT, UP, movewindow, u"
        "$mod SHIFT, RIGHT, movewindow, r"

        # Creates a group
        "$mod, W, togglegroup"

        # Focus navigation between tabs
        "$mod, LEFT, changegroupactive, b"
        "$mod, RIGHT, changegroupactive, f"
        "$mod, UP, changegroupactive, b"
        "$mod, DOWN, changegroupactive, f"

        # Move window into/out of tab groups (i3-like)
        "$mod SHIFT, LEFT, moveintogroup, l"
        "$mod SHIFT, RIGHT, moveintogroup, r"
        "$mod SHIFT, UP, moveintogroup, u"
        "$mod SHIFT, DOWN, moveintogroup, d"

        # Optional: move window within group tab order (like i3 move left/right)
        "$mod SHIFT, LEFT, movegroupwindow, b"
        "$mod SHIFT, RIGHT, movegroupwindow, f"

        # Resize
        "$mod CTRL, LEFT, resizeactive, -10 0"
        "$mod CTRL, DOWN, resizeactive, 10 0"
        "$mod CTRL, UP, resizeactive, 0 -10"
        "$mod CTRL, RIGHT, resizeactive, 0 10"

        # --- Force split direction like i3 ---
        "$mod, H, layoutmsg, orientationhorizontal"
        "$mod, V, layoutmsg, orientationvertical"

        # Reload
        "$mod SHIFT, R, exec, hyprctl reload"

        # Brightness
        ", XF86MonBrightnessDown, exec, light -U 10"
        ", XF86MonBrightnessUp, exec, light -A 10"

        # Volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

        # Apps and scripts
        "$mod, D, exec, wofi --show drun --location top --width 100%"
        "$mod, RETURN, exec, ghostty"
        "$mod, C, exec, google-chrome-stable"
        "$mod SHIFT, C, exec, firefox"
        "$mod, O, exec, bash -c \"nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on\""
        "$mod, X, exec, bash -c \"$HOME/nixos/scripts/waybar.sh\""

        # Fullscreen
        "SUPER, F, fullscreenstate, 2 -1"
        "SUPER SHIFT, F, fullscreen"

        # Workspace
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
      ];
      animations = {
        enabled = true;
        bezier = "fast, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 2, fast"
          "windowsOut, 1, 2, fast, popin 80%"
          "border, 1, 2, fast"
          "fade, 1, 2, fast"
          "workspaces, 1, 2, fast"
        ];
      };

      # Monitor
      monitor = [
        "eDP-1,1920x1080@60,0x0,1"
      ];

      decoration = {
        # blur.enabled = false;
        shadow.enabled = false;
      };

      exec-once = [
        "hyprpm reload -n"
        "waybar"
        "hyprpaper"
        "fcitx5 -d"
        "bash -c \"$HOME/nixos/scripts/hyprback.sh\""
      ];

      general = {
        border_size = 0;
        gaps_in = 0;
        gaps_out = 0;
        no_border_on_floating = true;
        layout="hy3";
      };

      group = {
        auto_group = true;
      };
    };
  };

  xdg.configFile."wofi/style.css".text = ''
    window {
      border-radius: 0;
      background-color: rgba(30, 30, 46, 0.95);
      color: #ffffff;
    }

    #entry:selected {
        background-color: rgba(80, 80, 100, 0.7);
    }

    #input {
        background-color: rgba(50, 50, 70, 0.9);
        color: white;
        border: none;
    } '';
}
