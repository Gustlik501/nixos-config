{ pkgs, inputs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    #xwayland.enable = true;
    plugins = [
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix
    ];
    settings = {
      config = {
        xwayland = {
          enabled = true;
        };
      };
    };
  };

  xdg.configFile."hypr/hyprland.lua".force = true;
}
