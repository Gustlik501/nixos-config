{ config, pkgs, ...}: {

  imports = [
#    ../modules/home/hyprland.nix
 #   ../modules/home/plasma.nix
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
      htop
      runelite
      firefox
      vlc
      kde-gruvbox
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

}
