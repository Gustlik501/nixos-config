{ config, pkgs, ... }: {
  programs.rofi = {
    enable = true;
    theme = "${config.home.homeDirectory}/.cache/wal/colors-rofi-dark.rasi";
  };
}
