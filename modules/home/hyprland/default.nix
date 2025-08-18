{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
    ../swaync # Add SwayNC module
    ../waybar # Add Waybar module
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/UserKeybinds.conf
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/WindowRules.conf
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/UserDecorations.conf
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/Monitors.conf
  '';
}
