-- Keybindings migrated from hyprland_hy3.nix.
local hy3 = hl.plugin.hy3
local dispatchers = {
  ["hy3:movefocus"] = hy3.move_focus,
  ["hy3:movewindow"] = hy3.move_window,
  ["hy3:makegroup"] = hy3.make_group,
  ["hy3:changegroup"] = hy3.change_group,
  ["hy3:changefocus"] = hy3.change_focus,
}
local function dispatch(key, name, args)
  hl.bind(key, dispatchers[name](args))
end

hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())

dispatch("SUPER + H", "hy3:movefocus", "l")
dispatch("SUPER + L", "hy3:movefocus", "r")
dispatch("SUPER + K", "hy3:movefocus", "u")
dispatch("SUPER + J", "hy3:movefocus", "d")
dispatch("SUPER + LEFT", "hy3:movefocus", "l")
dispatch("SUPER + RIGHT", "hy3:movefocus", "r")
dispatch("SUPER + UP", "hy3:movefocus", "u")
dispatch("SUPER + DOWN", "hy3:movefocus", "d")

dispatch("SUPER + SHIFT + H", "hy3:movewindow", "l")
dispatch("SUPER + SHIFT + L", "hy3:movewindow", "r")
dispatch("SUPER + SHIFT + K", "hy3:movewindow", "u")
dispatch("SUPER + SHIFT + J", "hy3:movewindow", "d")
dispatch("SUPER + SHIFT + LEFT", "hy3:movewindow", "l")
dispatch("SUPER + SHIFT + RIGHT", "hy3:movewindow", "r")
dispatch("SUPER + SHIFT + UP", "hy3:movewindow", "u")
dispatch("SUPER + SHIFT + DOWN", "hy3:movewindow", "d")

dispatch("SUPER + B", "hy3:makegroup", "h")
dispatch("SUPER + V", "hy3:makegroup", "v")
dispatch("SUPER + E", "hy3:changegroup", "opposite")
dispatch("SUPER + W", "hy3:makegroup", "tab")
dispatch("SUPER + SPACE", "hy3:changefocus", "raise")
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + A", hy3.focus_tab({ direction = "left" }))
hl.bind("SUPER + S", hy3.focus_tab({ direction = "right" }))

hl.bind("SUPER + CTRL + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind("SUPER + CTRL + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind("SUPER + CTRL + K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind("SUPER + CTRL + J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
hl.bind("SUPER + CTRL + LEFT", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind("SUPER + CTRL + RIGHT", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind("SUPER + CTRL + UP", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind("SUPER + CTRL + DOWN", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

hl.bind("SUPER + D", hl.dsp.exec_cmd("wofi --show drun --location top --width 100%"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + O", hl.dsp.exec_cmd("bash -c \"nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on\""))
hl.bind("SUPER + X", hl.dsp.exec_cmd("@waybarToggle@ hyprland"))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("@wallpaperToggle@"))

hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 1, client = -1 }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())

for workspace = 1, 9 do
  local key = tostring(workspace)
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar -c $HOME/.config/waybar/hyprland.json")
  hl.exec_cmd("fcitx5 -d")
end)
