{ config, pkgs, ... }:
{
  home.packages = [ pkgs.hyprlock ];

  xdg.configFile."hypr/hyprlock.conf".text = ''
    general {
      disable_loading_bar = true
      hide_cursor = true
    }

    background {
      monitor =
      path = ${config.home.homeDirectory}/nixos-config/wallpapers/dark.png
      blur_passes = 2
      blur_size = 6
    }

    label {
      monitor =
      text = $TIME
      font_family = JetBrainsMono Nerd Font
      font_size = 64
      color = rgba(255, 255, 255, 0.9)
      position = 0, 160
      halign = center
      valign = center
    }

    input-field {
      monitor =
      size = 320, 60
      outline_thickness = 2
      dots_size = 0.2
      dots_spacing = 0.35
      dots_center = true
      outer_color = rgba(255, 255, 255, 0.2)
      inner_color = rgba(0, 0, 0, 0.5)
      font_color = rgba(255, 255, 255, 0.9)
      fade_on_empty = false
      placeholder_text = Type to unlock
      position = 0, -40
      halign = center
      valign = center
    }
  '';
}
