-- Custom Hyprland keybinds.
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local bin     = os.getenv("HOME") .. "/.local/bin"

hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(bin .. "/display-keybinds"), { description = "Show keyboard shortcuts" })
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(bin .. "/bgselector"), { description = "Choose wallpaper" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(bin .. "/cwal-theme-selector"), { description = "Choose colour theme" })

hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd("rofi -show drun"), { description = "Open application launcher" })
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(bin .. "/clipboard"), { description = "Open clipboard history" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"), { description = "Clear clipboard history" })
hl.bind(mainMod .. " + SPACE",     hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(mainMod .. " + Q",         hl.dsp.window.close(), { description = "Close focused window" })

-- Move the focused window
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = "Focus window to the left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus window to the right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Focus window above" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Focus window below" })

hl.bind("ALT + tab",       hl.dsp.window.cycle_next(), { description = "Cycle windows" })
hl.bind(mainMod .. " + f", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Open terminal" })
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(bin .. "/powermenu"), { description = "Open power menu" })
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("thunar"), { description = "Open file manager" })
hl.bind(mainMod .. " + S",      hl.dsp.exec_cmd("grimblast copy area"), { description = "Copy screenshot of selected area" })

-- mouse:272 = left click, mouse:273 = right click
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Workspaces
hl.bind(mainMod .. " + tab",         hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace on this monitor" })
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace on this monitor" })

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "Move window to special workspace" })
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special(""), { description = "Toggle special workspace" })

-- Keycodes are used instead of key names so the binds survive layout switches.
-- code:10 is key 1, code:11 is key 2, ... code:19 is key 0 (workspace 10).
for ws = 1, 10 do
    local key = "code:" .. (9 + ws)

    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = ws }), { description = "Switch to workspace " .. ws })
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = ws }), { description = "Move window to workspace " .. ws })
    -- follow = false is the old `movetoworkspacesilent`
    hl.bind(mainMod .. " + CTRL + " .. key,    hl.dsp.window.move({ workspace = ws, follow = false }), { description = "Send window to workspace " .. ws .. " without switching" })
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }), { description = "Move window to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), { description = "Move window to next workspace" })
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }), { description = "Send window to previous workspace without switching" })
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "Send window to next workspace without switching" })

-- Cycle through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next existing workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Previous existing workspace" })
hl.bind(mainMod .. " + period",     hl.dsp.focus({ workspace = "e+1" }), { description = "Next existing workspace" })
hl.bind(mainMod .. " + comma",      hl.dsp.focus({ workspace = "e-1" }), { description = "Previous existing workspace" })
