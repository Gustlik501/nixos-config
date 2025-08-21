{ pkgs, inputs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix
    ];
    settings = {
      "exec-once" = [
        "hyprpaper"
        "hyprpanel" # Add waybar here
      ];
      plugin = {
        csgo-vulkan-fix = {
          res = "1920x1080";
        };
      };
    };
  };
}
