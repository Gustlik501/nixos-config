-- laptop monitor config
-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Internal display
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- TV (rarely plugged in)
hl.monitor({ output = "HDMI-A-2", mode = "1280x720", position = "auto", scale = 1 })
