{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    swaync
  ];

  xdg.configFile."swaync/config.json".source = ./config.json;
  xdg.configFile."swaync/style.css".source = ./style.css;
}