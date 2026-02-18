{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../zsh
    ../btop
    ../nvf
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  home.packages = with pkgs; [
    lazygit
    git
    git-lfs
    curl
    wget
    tree
    eza
    btop
    ripgrep
    fastfetch
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --grid --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
    };
  };
}
