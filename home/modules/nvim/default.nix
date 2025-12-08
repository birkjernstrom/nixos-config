{ config, pkgs, inputs, settings, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./keymaps.nix
  ];

  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        vimAlias = true;
        globals = {
          mapleader = " ";
          maplocalleader = " ";
        };
        options = {
          tabstop = 2; 
          shiftwidth = 2;
          wrap = false;
          updatetime = 250;
          timeoutlen = 300;
        };
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        git.gitsigns = {
          enable = true;
        };

        statusline.lualine.enable = true;
        autocomplete.nvim-cmp.enable = true;
        diagnostics.nvim-lint.enable = true;

        utility.snacks-nvim = {
          enable = true;
          setupOpts = {
            picker = { enable = true; };
            input = { enable = true; };
            git = { enable = true; };
            gh = { enable = true; };
            gitbrowse = { enable = true; };
          };
        };

        filetree.neo-tree = {
          enable = true;
        };

        navigation.harpoon = {
          enable = true;
          mappings = {
            listMarks = "<C-b>";
            markFile = "<leader>b";
            file1 = "<M-1>";
            file2 = "<M-2>";
            file3 = "<M-3>";
            file4 = "<M-4>";
          };
        };

        formatter.conform-nvim = {
          enable = true;
          setupOpts = {
            formatters_by_ft = {
              lua = [ "stylua" ];
              python = [ "ruff" "black" ];
              javascript = [ "prettierd" "prettier" ];
              typescript = [ "prettierd" "prettier" ];
              javascriptreact = [ "prettierd" "prettier" ];
              typescriptreact = [ "prettierd" "prettier" ];
            };
          };
        };

        lsp = {
          enable = true;
          mappings = {
            renameSymbol = "<leader>cr";
            codeAction = "<leader>ca";
          };
        };

        languages = {
          enableDAP = true;
          enableTreesitter = true;
          enableFormat = true;

          nix.enable = true;
          lua.enable = true;
          ts.enable = true;
          clang.enable = true;
          python.enable = true;
          rust.enable = true;
          go.enable = true;
          markdown.enable = true;
          html.enable = true;
          tailwind.enable = true;
        };
      };
    };
  };
}
