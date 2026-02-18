# zsh-with-aliases.nix
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    # Completions + QoL
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    # Nice defaults (optional but handy)
    history = {
      save = 50000;
      size = 50000;
      extended = true;
      share = true;
      ignoreDups = true;
    };

    # Your aliases
    shellAliases = {
      lg = "lazygit";
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --grid --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
    };

    # Extra init (optional): better completion UI, sane keybinds
    initContent = ''
      # Use menu completion with navigation
      zmodload zsh/complist
      bindkey '^I' complete-word
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # Enable correction hints (does not auto-run)
      setopt correct

      # Keep completion cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.cache/zsh/.zcompcache
    '';
  };

}
