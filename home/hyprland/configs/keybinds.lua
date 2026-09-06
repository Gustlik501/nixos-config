-- Custom Hyprland keybinds.
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local bin     = os.getenv("HOME") .. "/.local/bin"

hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(bin .. "/display-keybinds"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(bin .. "/bgselector"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(bin .. "/cwal-theme-selector"))

hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(bin .. "/clipboard"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))
hl.bind(mainMod .. " + SPACE",     hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())

-- Move the focused window
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind("ALT + tab",       hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + f", hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(bin .. "/powermenu"))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + S",      hl.dsp.exec_cmd("grimblast copy area"))

-- mouse:272 = left click, mouse:273 = right click
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
hl.bind(mainMod .. " + tab",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special(""))

-- Keycodes are used instead of key names so the binds survive layout switches.
-- code:10 is key 1, code:11 is key 2, ... code:19 is key 0 (workspace 10).
for ws = 1, 10 do
    local key = "code:" .. (9 + ws)

    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = ws }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = ws }))
    -- follow = false is the old `movetoworkspacesilent`
    hl.bind(mainMod .. " + CTRL + " .. key,    hl.dsp.window.move({ workspace = ws, follow = false }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }))

-- Cycle through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + period",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + comma",      hl.dsp.focus({ workspace = "e-1" }))
