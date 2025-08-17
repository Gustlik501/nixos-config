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
          format = "{:%H:%M}";
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
    style = ''
      /* Basic Waybar styling */
      @import "${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita/index.theme";
      @import "${pkgs.papirus-icon-theme}/share/icons/Papirus/index.theme";

      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrains Mono Nerd Font";
        font-size: 14px;
      }

      window#waybar {
        background: rgba(0, 0, 0, 0.7);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: #ffffff;
      }

      #workspaces button.focused {
        background: #4c7899;
      }

      #mode {
        background: #64727D;
        border-bottom: 3px solid #ffffff;
      }

      #clock, #pulseaudio, #tray {
        padding: 0 10px;
        margin: 0 5px;
        background: #333333;
      }
    '';
  };
}
