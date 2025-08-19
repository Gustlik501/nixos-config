{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
    ../waybar # Add Waybar module
    ../hyprpanel
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = /home/gustl/nixos-config/home/hyprland/configs/UserKeybinds.conf
    source = /home/gustl/nixos-config/home/hyprland/configs/WindowRules.conf
    source = /home/gustl/nixos-config/home/hyprland/configs/UserDecorations.conf
    source = /home/gustl/nixos-config/home/hyprland/configs/Monitors.conf
  '';
}
