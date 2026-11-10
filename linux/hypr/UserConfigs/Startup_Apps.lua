-- Commands and Apps to be executed at launch

local scriptsDir = HOME .. "/.config/hypr/scripts"
-- empty = image wallpaper via swww; a video path = live wallpaper via mpvpaper (set by WallpaperSelect.sh)
local livewallpaper = ""

hl.on("hyprland.start", function()
    -- SDDM autologins, so this is the only password prompt at boot
    hl.exec_cmd("hyprlock")
    if livewallpaper ~= "" then
        hl.exec_cmd("mpvpaper '*' -o \"load-scripts=no no-audio --loop\" '" .. livewallpaper .. "'")
    else
        hl.exec_cmd("swww-daemon --format xrgb")
    end
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start auto-ajuste-standby.service")
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd(scriptsDir .. "/NotifyLogger.sh")
    hl.exec_cmd("ags")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("waybar")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd(scriptsDir .. "/ThemeSync.sh")
    hl.exec_cmd("$HOME/.local/bin/hyprland-dock --daemonize")
    hl.exec_cmd("hypridle")
end)

