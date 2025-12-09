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

        utility = {
          snacks-nvim = {
            enable = true;
            setupOpts = {
              picker = { enable = true; };
              input = { enable = true; };
              git = { enable = true; };
              gh = { enable = true; };
              gitbrowse = { enable = true; };
            };
          };
          undotree.enable = true;
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

        diagnostics.nvim-lint = {
          enable = true;
          linters_by_ft = {
            javascript = [ "eslint_d" ];
            typescript = [ "eslint_d" ];
            javascriptreact = [ "eslint_d" ];
            typescriptreact = [ "eslint_d" ];
            python = [ "ruff" "mypy" ];
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
          trouble.enable = true;
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
          tailwind.enable = true;
          html.enable = true;
        };

        treesitter = {
          autotagHtml = true;
          textobjects = {
            enable = true;
            setupOpts = {
              select = {
                enable = true;
                lookahead = true;
                keymaps = {
                  "aa" = "@parameter.outer";
                  "ia" = "@parameter.inner";
                  "af" = "@function.outer";
                  "if" = "@function.inner";
                  "ac" = "@class.outer";
                  "ic" = "@class.inner";
                };
              };
              move = {
                enable = true;
                set_jumps = true;
                goto_next_start = {
                  "]m" = "@function.outer";
                  "]]" = "@class.outer";
                };
                goto_next_end = {
                  "]M" = "@function.outer";
                  "][" = "@class.outer";
                };
                goto_previous_start = {
                  "[m" = "@function.outer";
                  "[[" = "@class.outer";
                };
                goto_previous_end = {
                  "[M" = "@function.outer";
                  "[]" = "@class.outer";
                };
              };
              swap = {
                enable = true;
                swap_next = {
                  "<leader>a" = "@parameter.inner";
                };
                swap_previous = {
                  "<leader>A" = "@parameter.inner";
                };
              };
            };
          };
        };
      };
    };
  };
}
