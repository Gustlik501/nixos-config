{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "tray" "pulseaudio" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰎤";
            "2" = "󰎧";
            "3" = "󰎪";
            "4" = "󰎭";
            "5" = "󰎰";
            "6" = "󰎳";
            "7" = "󰎶";
            "8" = "󰎹";
            "9" = "󰎼";
            "10" = "󰎿";
            "urgent" = "";
            "focused" = "";
            "default" = "";
          };
        };

        clock = {
          format = "{0:%H:%M}";
          tooltip-format = "<big>{:%Y %B %d}</big>\n<small>{:%A}</small>";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}%";
          format-muted = " {volume}%";
          format-icons = {
            default = [ "" "" ];
            muted = "";
          };
        };

        tray = {
          spacing = 10;
        };
      };
    };
    style = ./style.css;
  };
}
