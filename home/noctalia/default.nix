{ inputs, pkgs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    settings = {
      shell = {
        font_family = "JetBrainsMono Nerd Font";
      };

      bar.main = {
        position = "top";
        background_opacity = 0.0;
      };

      location = {
        address = "Dravograd, Slovenia";
      };

      wallpaper = {
        enabled = false;
      };

      theme = {
        source = "wallpaper";
      };
    };
  };
}
