{ config, pkgs, lib, inputs, theme, ... }:

with lib; let
  cfg = config.userSettings.cli.nvim;

  # Theme plugin (if the theme requires a custom plugin not built into nvf)
  hasCustomPlugin = theme.nvim.plugin != null;
  hasCustomConfig = theme.nvim.config != null;

  # nvf DAG helper for luaConfigRC entries
  nvimDag = inputs.nvf.lib.nvim.dag;
in
{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./keymaps.nix
  ];

  options.userSettings.cli.nvim.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Nvim";
  };

  config = mkIf cfg.enable {
    # Disable Stylix nvf theming - we use our own theme configuration
    stylix.targets.nvf.enable = false;

    home.packages = with pkgs; [
      neovim
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
          # Theme plugin (if the theme requires one not built into nvf)
          startPlugins = mkIf hasCustomPlugin [ theme.nvim.plugin ];

          # Theme configuration (wrapped in DAG entry for nvf)
          luaConfigRC.theme = mkIf hasCustomConfig (nvimDag.entryAnywhere theme.nvim.config);

          git = {
            gitsigns = {
              enable = true;
            };
          };

          binds = {
            whichKey = {
              enable = true;
            };
          };

          statusline = {
            lualine.enable = true;
          };

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

          mini = {
            pairs.enable = true;
            ai.enable = true;
            surround.enable = true;
            comment.enable = true;
            snippets.enable = true;
          };

          assistant = {
            copilot = {
              enable = true;
              cmp.enable = true;
            };
          };

          autocomplete = {
            nvim-cmp = {
              enable = true;
              sourcePlugins = [
                "copilot-cmp"
                "cmp-nvim-lsp"
                "mini-snippets"
                "cmp-buffer"
                "cmp-path"
              ];
            };
          };

          filetree = {
            neo-tree = {
              enable = true;
            };
          };

          navigation = {
            harpoon = {
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
          };

          diagnostics = {
            nvim-lint = {
              enable = true;
              linters_by_ft = {
                javascript = [ "eslint_d" ];
                typescript = [ "eslint_d" ];
                javascriptreact = [ "eslint_d" ];
                typescriptreact = [ "eslint_d" ];
                python = [ "ruff" "mypy" ];
              };
            };
          };

          formatter = {
            conform-nvim = {
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
  };
}
