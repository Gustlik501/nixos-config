-- Decoration, animation and group styling.
-- https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        border_size = 0,
        gaps_in     = 3,
        gaps_out    = 2,

        col = {
            active_border   = "rgb(9EA996)",
            inactive_border = "rgb(7A6E63)",
        },
    },

    decoration = {
        rounding = 0,

        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.0,
        dim_special  = 0.8,

        shadow = {
            enabled        = true,
            range          = 2,
            render_power   = 1,
            color          = "rgb(9EA996)",
            color_inactive = "rgb(7A6E63)",
        },

        blur = {
            enabled           = false,
            size              = 2,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            special           = true,
            popups            = true,
        },
    },

    animations = {
        enabled = false,
    },

    group = {
        col = {
            border_active = "rgb(F4EFDA)",
        },

        groupbar = {
            col = {
                active = "rgb(010000)",
            },
        },
    },
})

-- Animations are globally disabled above; these per-leaf settings are kept from
-- the old hyprlang config so flipping `animations.enabled` back on restores them.
hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })
