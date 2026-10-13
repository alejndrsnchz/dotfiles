-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55+ Lua config

---------------------
---- MY PROGRAMS ----
---------------------

local mainMod     = "SUPER"
local terminal    = "alacritty"
local fileManager = "nautilus"
local menu        = "rofi -show run"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("hyprctl setcursor WhiteSur-cursors 24")

end)
--------------------
---- APPEARANCE ----
--------------------
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 4,
        border_size = false,
        layout      = "qtile",
    },

    decoration = {
        rounding         = 25,
        -- Sin opacity global, Hyprland lo maneja por window rule solo en alacritty
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow           = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000040)",
            offset = {0, 2},
        },

        blur             = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            ignore_opacity    = true,
            new_optimizations = true,
            xray              = true,
            contrast = 0.90,
            brightness = 1.0,
            vibrancy = 0.10,
            noise = 0.01,
        },
    },
})



--------------------
---- ANIMATIONS ----
--------------------

hl.curve("macOS", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("soft", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 7, bezier = "macOS", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "smoothOut", style = "popin 87%" })
hl.animation({ leaf = "border", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "soft" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "macOS", style = "slidefade" })

----------------------
---- WINDOW RULES ----
----------------------

-- Todo sin blur ni transparencia
hl.window_rule({ match = { class = ".*" }, no_blur = true, opacity = "1.0 override 1.0 override", border_size = 2, border_color = "rgba(ffffff99)"})

-- Solo Alacritty: blur ON, opacity activa 0.80 / inactiva 0.60
hl.window_rule({ match = { class = "Alacritty" }, no_blur = false, opacity = "0.59 0.48" })
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.01,
})

hl.window_rule({
    name = "termplayer",
    match = {
        class = "^termplayer$",
    },

    float = true,
    size = { 920, 600 },
    center = true,

    rounding = 18,
    border_size = 2,
    border_color = "rgba(ffffff99)",
    no_blur = false,
    opacity = "0.59 0.48",
    dim_around = true,
})

--------------------
---- KEYBINDINGS ----
--------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("quickshell -c hyprquickpaper"))

hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind(mainMod .. " + M", function()
    hl.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")
end)
-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- Media
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl pause"))
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioStop",        hl.dsp.exec_cmd("playerctl stop"))


hl.bind("SUPER + LEFT",  hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + UP",    hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + DOWN",  hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .." + M",       hl.dsp.exec_cmd("kitty --class termplayer -e bash -lc 'cd ~/Programation/Utils/TermPlayer/ && .venv/bin/python -m src'"))
-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"))
-- Workspaces: switch
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

-- Workspaces: mover ventana
for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- now lets move from obsolete to new syntax

hl.bind(mainMod .. " + X", hl.dsp.focus({ workspace = 10 }))

--------------------
---       ENV    ----
--------------------
env = {
    "QT_QPA_PLATFORMTHEME=qt6ct",
    "QT_STYLE_OVERRIDE=kvantum",
}
