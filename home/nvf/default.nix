{ config, pkgs, ... }: {
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = false;
        vimAlias = true;
        
        theme = {
          enable = true;
          name = "gruvbox";
          style = "dark";
        };

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        languages.enableLSP = true;
        languages.enableTreesitter = true;
        languages.nix.enable = true;
        
      };
    };
  };
}
