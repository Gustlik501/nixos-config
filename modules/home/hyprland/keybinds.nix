{ pkgs, ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
    # Keybind to switch wallpaper
    # You might need to change eDP-1 to your monitor's name
    bind = SUPER, W, exec, hyprctl hyprpaper wallpaper "eDP-1,/home/gustl/nixos-config/wallpapers/light.png"
  '';
}
