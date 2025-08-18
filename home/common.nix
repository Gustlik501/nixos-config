{ config, pkgs, ...}: {

  imports = [
   ../modules/home/hyprland
   ../modules/home/plasma.nix
   ../modules/home/kitty
   ../modules/home/rofi
   ../modules/home/wlogout
   ../modules/home/hyprpanel
   ../modules/home/btop
   ../modules/home/zsh
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

  wlogout.enable = true;

}
