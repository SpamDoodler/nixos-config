{
  config,
  pkgs,
  ...
}: 

{
  home.packages = with pkgs; [
    hyprpaper
    wofi
    brightnessctl
  ];

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "${config.home.homeDirectory}/Pictures/anime_wallpapers/sfw/default.jpeg"
      ];
      wallpaper = [
        "eDP-1,${config.home.homeDirectory}/Pictures/anime_wallpapers/sfw/default.jpeg"
      ];
    };
  };

 
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];

    # Use hyprstack instead of hy3
    plugins = [
    ];

    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod SHIFT, Q, killactive"

        # --- Focus movement (i3-style) ---
        "$mod, LEFT, movefocus, l"
        "$mod, DOWN, movefocus, d"
        "$mod, UP, movefocus, u"
        "$mod, RIGHT, movefocus, r"

        # --- Move window (i3-style) ---
        "$mod SHIFT, LEFT, movewindow, l"
        "$mod SHIFT, DOWN, movewindow, d"
        "$mod SHIFT, UP, movewindow, u"
        "$mod SHIFT, RIGHT, movewindow, r"

        # --- Layout switching (hyprstack) ---
        # Tabbed layout
        # "$mod, W, plugin:hyprstack:cyclestack, tab"

        # Split horizontal/vertical
        "$mod, H, layoutmsg, orientation h"
        "$mod, V, layoutmsg, orientation v"

        # Toggle split orientation (similar to hy3: togglesplit)
        "$mod, E, layoutmsg, togglesplit"

        # Switch stack order (similar to stacking)

        # --- Resize active window ---
        "$mod CTRL, LEFT, resizeactive, -50 0"
        "$mod CTRL, RIGHT, resizeactive, 50 0"
        "$mod CTRL, UP, resizeactive, 0 -50"
        "$mod CTRL, DOWN, resizeactive, 0 50"

        # Reload
        "$mod SHIFT, R, exec, hyprctl reload"

        # Brightness
        ", XF86MonBrightnessDown, exec, brightnessctl 10%+"
        ", XF86MonBrightnessUp, exec, brightnessctl 10%-"

        # Volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

        # Applications
        "$mod, D, exec, wofi --show drun --location top --width 100%"
        "$mod, RETURN, exec, ghostty"
        "$mod, C, exec, google-chrome-stable"
        "$mod SHIFT, C, exec, firefox"
        "$mod, O, exec, bash -c \"nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on\""
        "$mod, X, exec, bash -c \"$HOME/nixos/scripts/waybar.sh\""
        "$mod, B, exec, bash -c \"$HOME/nixos/scripts/set_wallpapers.sh\""

        # Fullscreen
        "SUPER, F, fullscreenstate, 2 -1"
        "SUPER SHIFT, F, fullscreen"

        # Workspaces
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

      monitor = [
        "eDP-1,1920x1080@60,0x0,1"
      ];

      decoration = {
        shadow.enabled = false;
      };

      exec-once = [
        "hyprpm reload -n"
        "waybar"
        "fcitx5 -d"
        "bash -c \"$HOME/nixos/scripts/hyprback.sh\""
      ];

      general = {
        border_size = 0;
        gaps_in = 0;
          gaps_out = 0;
          # no_border_on_floating = true;
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
