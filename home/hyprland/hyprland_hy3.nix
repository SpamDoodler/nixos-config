{
  config,
  pkgs,
  hyprland,
  hy3,
  ...
}: 

{
  home.packages = with pkgs; [
    hyprpaper
    wofi
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

    plugins = [
      hy3.packages.x86_64-linux.hy3
    ];

    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod SHIFT, Q, killactive"

        # --- hy3: Focus movement (vim keys + arrows) ---
        "$mod, H, hy3:movefocus, l"
        "$mod, L, hy3:movefocus, r"
        "$mod, K, hy3:movefocus, u"
        "$mod, J, hy3:movefocus, d"
        "$mod, LEFT, hy3:movefocus, l"
        "$mod, RIGHT, hy3:movefocus, r"
        "$mod, UP, hy3:movefocus, u"
        "$mod, DOWN, hy3:movefocus, d"

        # --- hy3: Move window (vim keys + arrows) ---
        "$mod SHIFT, H, hy3:movewindow, l"
        "$mod SHIFT, L, hy3:movewindow, r"
        "$mod SHIFT, K, hy3:movewindow, u"
        "$mod SHIFT, J, hy3:movewindow, d"
        "$mod SHIFT, LEFT, hy3:movewindow, l"
        "$mod SHIFT, RIGHT, hy3:movewindow, r"
        "$mod SHIFT, UP, hy3:movewindow, u"
        "$mod SHIFT, DOWN, hy3:movewindow, d"

        # --- hy3: Container management (i3-style) ---
        # Split horizontal/vertical
        "$mod, B, hy3:makegroup, h"  # horizontal split
        "$mod, V, hy3:makegroup, v"  # vertical split
        
        # Toggle split orientation
        "$mod, E, hy3:changegrouporient, togglesplit"
        
        # Tabbed layout (i3-style)
        "$mod, W, hy3:makegroup, tab"
        
        # Change focus between tiling/floating
        "$mod, Space, hy3:changefocus, raise"
        
        # Toggle floating
        "$mod SHIFT, Space, togglefloating"

        # --- hy3: Tab navigation ---
        "$mod, A, hy3:changefocus, left, visible"   # previous tab
        "$mod, S, hy3:changefocus, right, visible"  # next tab

        # --- Resize active window ---
        "$mod CTRL, H, resizeactive, -50 0"
        "$mod CTRL, L, resizeactive, 50 0"
        "$mod CTRL, K, resizeactive, 0 -50"
        "$mod CTRL, J, resizeactive, 0 50"
        "$mod CTRL, LEFT, resizeactive, -50 0"
        "$mod CTRL, RIGHT, resizeactive, 50 0"
        "$mod CTRL, UP, resizeactive, 0 -50"
        "$mod CTRL, DOWN, resizeactive, 0 50"

        # Reload
        "$mod SHIFT, R, exec, hyprctl reload"

        # Brightness
        ", XF86MonBrightnessDown, exec, light -U 10"
        ", XF86MonBrightnessUp, exec, light -A 10"

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
        "$mod SHIFT, B, exec, bash -c \"$HOME/nixos/scripts/set_wallpapers.sh\""

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
        border_size = 2;
        gaps_in = 5;
        gaps_out = 10;
        "col.active_border" = "rgba(88888888)";
        "col.inactive_border" = "rgba(00000088)";
        no_border_on_floating = false;
      };

      # hy3 plugin settings
      plugin = {
        hy3 = {
          # no_gaps_when_only = false;  # set to true for i3 gaps behavior
          
          tabs = {
            height = 15;
            padding = 5;
            render_text = true;
            "col.active" = "rgba(88888888)";
            "col.inactive" = "rgba(00000088)";
            "col.urgent" = "rgba(ff0000ff)";
          };
          
          autotile = {
            enable = true;
            trigger_width = 800;
            trigger_height = 500;
          };
        };
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
    }
  '';
}
