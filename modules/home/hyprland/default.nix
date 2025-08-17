{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/UserKeybinds.conf
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/WindowRules.conf
    source = /home/gustl/nixos-config/modules/home/hyprland/configs/UserDecorations.conf
  '';
}
