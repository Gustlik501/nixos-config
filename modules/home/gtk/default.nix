{ config, pkgs, ... }:
{
  # Enable GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox";
      package = pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      enable = true;
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  # Enable Qt apps to follow the GTK theme
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # Optionally install a matching terminal theme for kitty
  programs.kitty = {
    enable = true;
    settings = {
      # Load colors from gruvbox theme automatically (needs out-path)
      include = "${pkgs.gruvbox-gtk-theme}/share/themes/Gruvbox/gtk-3.0/kitty.conf";
      # Fallback: explicit color definitions could go here if needed.
    };
  };

  # Make sure the theme packages are available
  home.packages = with pkgs; [
    gruvbox-gtk-theme
    papirus-icon-theme
    bibata-cursors
    kitty
  ];
}
