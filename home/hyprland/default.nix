{ pkgs, inputs, config, osConfig, ... }:
let
  hostName = osConfig.networking.hostName or "";
  monitorsFile =
    if hostName == "desktop" then "Monitors.desktop.conf" else
    if hostName == "laptop" then "Monitors.laptop.conf" else
    "Monitors.conf";
in
{
  imports = [
    (import ./hyprland.nix { inherit pkgs inputs; })
    #./hyprpaper.nix
    ../noctalia
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ${config.xdg.configHome}/hypr/nixos/UserKeybinds.conf
    source = ${config.xdg.configHome}/hypr/nixos/WindowRules.conf
    source = ${config.xdg.configHome}/hypr/nixos/UserDecorations.conf
    source = ${config.xdg.configHome}/hypr/nixos/${monitorsFile}
    source = ${config.xdg.configHome}/hypr/nixos/default.conf
  '';
}
