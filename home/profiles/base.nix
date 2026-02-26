{
  pkgs,
  inputs,
  username,
  ...
}:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
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
    gh
    git-lfs
    curl
    wget
    tree
    eza
    btop
    ripgrep
    fastfetch
    python3
    gogcli
    llmAgents.codex
    llmAgents.gemini-cli
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
