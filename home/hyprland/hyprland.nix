{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
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
