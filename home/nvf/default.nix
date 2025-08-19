{ config, pkgs, ... }:
{
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

        ui.smartcolumn.enable = true;
        ui.smartcolumn.setupOpts.colorcolumn = "80";

        globals.mapLeader = " ";

        keymaps = [
          {
            key = "<leader>ff";
            mode = [ "n" ];
            action = "<cmd>Telescope find_files<CR>";
            silent = true;
            desc = "Save file and quit";
          }
          {
            mode = "n";
            key = "<leader>fg";
            action = "<cmd>Telescope live_grep<CR>";
            desc = "Live grep with Telescope";
          }
          {
            mode = "n";
            key = "<C-s>";
            action = "<cmd>w<CR>";
          }
          {
            mode = "i";
            key = "<C-s>";
            action = "<Esc><cmd>w<CR>a";
          }
          # Normal mode: copy (yank) current line
          {
            mode = "n";
            key = "<C-c>";
            action = "\"+yy";
            desc = "Copy line to clipboard";
            silent = true;

          }
          # Visual mode: copy selection
          {
            mode = "v";
            key = "<C-c>";
            action = "\"+y";
            desc = "Copy selection to clipboard";
            silent = true;

          }

          # --- Cut ---
          # Normal mode: cut (delete) current line
          {
            mode = "n";
            key = "<C-x>";
            action = "\"+dd";
            desc = "Cut line to clipboard";
            silent = true;

          }
          # Visual mode: cut selection
          {
            mode = "v";
            key = "<C-x>";
            action = "\"+d";
            desc = "Cut selection to clipboard";
            silent = true;
          }

          # --- Paste ---
          # Normal mode: paste
          {
            mode = "n";
            key = "<C-v>";
            action = "\"+p";
            desc = "Paste from clipboard";
            silent = true;

          }
          # Visual mode: paste (replace selection)
          {
            mode = "v";
            key = "<C-v>";
            action = "\"+p";
            desc = "Paste over selection";
            silent = true;

          }
          # Insert mode: paste and return to insert
          {
            mode = "i";
            key = "<C-v>";
            action = "<Esc>\"+pa";
            desc = "Paste in insert mode";
            silent = true;

          }
        ];

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        lsp.enable = true;
        lsp.formatOnSave = true;
        languages.enableTreesitter = true;
        languages.nix.enable = true;

      };
    };
  };
}
