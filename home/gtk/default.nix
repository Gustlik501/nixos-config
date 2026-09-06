# gruvbox-theme.nix
{ pkgs, ... }:
{
  home.sessionVariables = {
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "breeze_cursors";
    HYPRCURSOR_SIZE = "24";
  };

  gtk = {
    enable = true;

    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark-gtk";
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    cursorTheme = {
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.packages = with pkgs; [
    gruvbox-dark-gtk
    papirus-icon-theme
    kdePackages.breeze
  ];
}
