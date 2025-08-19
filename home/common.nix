{ config, pkgs, ...}: {

  imports = [
   ./hyprland
   ./plasma.nix
   ./kitty
   ./rofi
   ./wlogout
   ./hyprpanel
   ./btop
   ./zsh
   ./gtk
  ];

  home = {
    username = "gustl";
    homeDirectory = "/home/gustl";
    stateVersion = "23.11"; 


    packages = with pkgs; [
      tree
      git
      lazygit
      openssh
      curl
      wget
      neofetch
      btop
      runelite
      firefox
      vlc
      gemini-cli
      ripgrep
      vesktop
      dart-sass
      wl-clipboard
      gtksourceview3
      libsoup_3
      libgtop

      # Thunar + helpers
      xfce.thunar
      xfce.thunar-volman
      xfce.thunar-archive-plugin
      xfce.tumbler

      deluge
      gimp
      obsidian
    ];
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox-material
      nerdtree
    ];
  };

  programs.git = {
   enable = true;
   userEmail = "sevcnikar.gregor2@gmail.com";
   userName = "Gustlik501";
  };

  home.sessionVariables.TERMINAL = "kitty";

  # Make Thunar the default file manager
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/x-directory" = [ "thunar.desktop" ];
      "x-scheme-handler/terminal" = "kitty.desktop";
    };
  };

  wlogout.enable = true;

}
