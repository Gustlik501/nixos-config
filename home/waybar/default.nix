{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-center = [ "hyprland/workspaces" ];
        modules-left = [ "wireplumber" ];
        modules-right = [ "network" "cpu" "memory" "battery" "clock" ];

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


        network = {
          tooltip = false;
          "format-wifi" = "  {essid}";
          "format-ethernet" = "󰈀 {ifname}";
          "format-disconnected" = " no net";
          "on-click" = "kitty -- nmtui";
        };


        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%m-%d-%Y}";
        };

        cpu = {
          interval = 15;
          format = "  {}%";
          max-length = 10;
          on-click = "kitty -- btop";
        };

        memory = {
          interval = 15;
          format = "  {}%";
          max-length = 10;
        };


        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = " mute";
          format-icons = {
            headphones = "";
            speaker = "";
            hdmi = "";
            default = "";
          };

          # Actions
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";

          # Middle click: cycle through sinks
          on-click-middle = ''
            wpctl set-default $(
              wpctl status \
                | awk '/Sink/{getline; print $2 " " $3 " " $4}' \
                | rofi -dmenu -p "Select Audio Sink" \
                | awk '{print $1}'
            )
          '';
        };

      };
    };
    style = ./style.css;
  };
}
