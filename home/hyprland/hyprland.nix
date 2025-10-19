{
  config,
  pkgs,
  ...
}: let
  hyprExtraConfig = builtins.readFile ./hyprland.conf;
in {
  home.packages = with pkgs; [
    hyprpaper
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];

    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod SHIFT, q, killactive"

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

        # Moving focus on the next or previous window inside the group
        "$mod, bracketleft, changegroupactive, b"
        "$mod, bracketright, changegroupactive, f"

        # Swapping the active window with the next or previous in a group
        "$mod SHIFT, bracketleft, movegroupwindow, b"
        "$mod SHIFT, bracketright, movegroupwindow, f"

        # Moving non-tabbed window inside tabbed group by direction
        "$mod SHIFT CONTROL, LEFT, moveintogroup, l"
        "$mod SHIFT CONTROL, RIGHT, moveintogroup, r"
        "$mod SHIFT CONTROL, UP, moveintogroup, u"
        "$mod SHIFT CONTROL, DOWN, moveintogroup, d"

        # Moving tabbed window out from the group
        "$mod SHIFT ALT, LEFT, moveoutofgroup, l"
        "$mod SHIFT ALT, RIGHT, moveoutofgroup, r"
        "$mod SHIFT ALT, UP, moveoutofgroup, u"
        "$mod SHIFT ALT, DOWN, moveoutofgroup, d"

        # Resize
        "$mod, LEFT, resizeactive, -10 0"
        "$mod, DOWN, resizeactive, 10 0"
        "$mod, UP, resizeactive, 0 -10"
        "$mod, RIGHT, resizeactive, 0 10"

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
        "$mod, RETURN, exec, ghostty"
        "$mod, C, exec, google-chrome-stable"
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
      };

      group = {
        auto_group = false;
      };
    };
    # extraConfig = hyprExtraConfig;
  };
}
