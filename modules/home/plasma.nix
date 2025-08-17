{ pkgs, lib, ... }:
let
  repoWp = builtins.toString (../../wallpapers);
  repoTp = builtins.toString (../../themes);
in {
    
    xdg.dataFile."color-schemes/Gruvbox.colors".source = "${repoTp}/Gruvbox.colors";

    programs.plasma = {
      enable = true;
      workspace = {
        # If you have a Gruvbox color scheme installed:
        colorScheme = "Gruvbox";      # or "GruvboxDark" depending on file name
        wallpaper   = "${repoWp}/dark.png";
        iconTheme   = "Papirus-Dark"; # optional, fits Gruvbox nicely
      };
    };

    home.packages = with pkgs; [
      kdePackages.breeze
      kdePackages.breeze-gtk
      papirus-icon-theme
    ];

}
