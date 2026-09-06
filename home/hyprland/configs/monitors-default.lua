-- default monitor config, used on hosts without a dedicated monitor file
-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Samsung (left)
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- Zowie (right, main)
hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "1920x0", scale = 1 })

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })

hl.monitor({ output = "Virtual-1", mode = "1920x1080", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1280x720", position = "auto", scale = 1 })
