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
    #../waybar # Add Waybar module
    ../noctalia
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/UserKeybinds.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/WindowRules.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/UserDecorations.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/${monitorsFile}
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/default.conf
  '';
}
