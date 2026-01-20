{ inputs, pkgs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    
    settings = {
      bar = {
        position = "top";
        useSeparateOpacity = true;
        backgroundOpacity = 0.0;
      };
      
      wallpaper = {
        enabled = false;
      };

      colorSchemes = {
        predefinedScheme = "Gruvbox";
        useWallpaperColors = false;
      };
    };
  };
}