{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = /home/gustl/nixos-config/modules/home/hyprland/keybinds.conf
  '';
}
