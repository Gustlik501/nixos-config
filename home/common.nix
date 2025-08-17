{ config, pkgs, ...}: {
  home = {
    username = "gustl";
    homeDirectory = "/home/gustl";
    stateVersion = "23.11"; 

    packages = with pkgs; [
      neofetch
      htop
      runelite
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
