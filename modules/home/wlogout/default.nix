{ config, pkgs, lib, ... }:

let
  wlogoutConfigDir = "${config.xdg.configHome}/wlogout";
in
{
  options.wlogout = {
    enable = lib.mkEnableOption "wlogout configuration";
  };

  config = lib.mkIf config.wlogout.enable {
    home.packages = with pkgs; [
      wlogout
    ];

    xdg.configFile."wlogout/layout".source = pkgs.writeText "wlogout-layout" ''
      {
          "label" : "lock",
          "action" : "loginctl lock-session", # Using loginctl directly
          "text" : "Lock",
          "keybind" : "l"
      }
      {
          "label" : "reboot",
          "action" : "systemctl reboot",
          "text" : "Reboot",
          "keybind" : "r"
      }
      {
          "label" : "shutdown",
          "action" : "systemctl poweroff",
          "text" : "Shutdown",
          "keybind" : "s"
      }
      {
          "label" : "logout",
          "action" : "hyprctl dispatch exit 0",
          "text" : "Logout",
          "keybind" : "e"
      }
      {
          "label" : "suspend",
          "action" : "systemctl suspend",
          "text" : "Suspend",
          "keybind" : "u"
      }
      {
          "label" : "hibernate",
          "action" : "systemctl hibernate",
          "text" : "Hibernate",
          "keybind" : "h"
      }
    '';

    xdg.configFile."wlogout/style.css".source = pkgs.writeText "wlogout-style" ''
      /* ----------- 💫 https://github.com/JaKooLit 💫 -------- */
      /* wallust-wlogout */

      /* Importing wallust colors - This path needs to be resolved or handled differently in Nix */
      /* For now, I'll comment it out or assume it's handled by a global theme */
      /* @import '../../.config/waybar/wallust/colors-waybar.css'; */

      window {
          font-size: 24pt;
          color: @foreground; /* text */
          background-color: rgba(30, 30, 46, 0.8);
      }

      button {
          background-repeat: no-repeat;
          background-position: center;
          background-size: 20%;
          background-color: rgba(200, 220, 255, 0);
          animation: gradient_f 10s ease-in infinite;
          transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682), box-shadow 0.2s ease-in-out, background-color 0.2s ease-in-out;
          border-radius: 80px;
          border:0px;
          outline-style: none;
      }

      button:focus {
          background-size: 50%;
          border: 0px;
          outline-style: none;

      }

      button:hover {
          background-color: transparent;
          color: @color13;
          background-size: 50%;
          margin: 30px;
          border-radius: 80px;
          outline-style: none;

      }

      /* Adjust the size of the icon or content inside the button */
      button span {
          font-size: 1.2em; /* Increase the font size */
      }


      #lock {
          background-image: image(url("icons/lock.png"));
      }
      #lock:hover {
          background-image: image(url("icons/lock-hover.png"));
      }

      #logout {
          background-image: image(url("icons/logout.png"));
      }
      #logout:hover {
          background-image: image(url("icons/logout-hover.png"));
      }

      #suspend {
          background-image: image(url("icons/sleep.png"));
      }
      #suspend:hover {
          background-image: image(url("icons/sleep-hover.png"));
      }

      #shutdown {
          background-image: image(url("icons/power.png"));
      }
      #shutdown:hover {
          background-image: image(url("icons/power-hover.png"));
      }

      #reboot {
          background-image: image(url("icons/restart.png"));
      }
      #reboot:hover {
          background-image: image(url("icons/restart-hover.png"));
      }

      #hibernate {
          background-image: image(url("icons/hibernate.png"));
      }
      #hibernate:hover {
          background-image: image(url("icons/hibernate.png"));
      }
    '';

    # Copy icons
    xdg.configFile."wlogout/icons".source = ./icons; # Updated path
  };
}