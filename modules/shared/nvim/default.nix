{ config, pkgs, lib, inputs, ... }:

with lib; let
  cfg = config.userSettings.cli.nvim;
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
    home.packages = with pkgs; [
      neovim
    ];

    # Stylix's nvf target sets the deprecated `lualine.theme`, so the theme is set here instead.
    stylix.targets.nvf.enable = false;

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
          # Colorscheme comes from the Stylix palette - but nvf bakes that
          # palette into the nvim package, and user packages come from
          # /etc/profiles, which a runtime theme switch (modules/nixos/themes)
          # does not touch. So re-apply it from the palette Stylix writes into
          # ~/.config for the active theme; running instances get the same call
          # from theme-switch.
          luaConfigPost = ''
            do
              local f = io.open(vim.fn.expand("~/.config/stylix/palette.json"))
              if f then
                local ok, palette = pcall(vim.json.decode, f:read("*a"))
                f:close()
                if ok and type(palette) == "table" then
                  local colors = {}
                  for slot, hex in pairs(palette) do
                    if slot:match("^base0%x$") then colors[slot] = "#" .. hex end
                  end
                  pcall(function() require("base16-colorscheme").setup(colors) end)
                end
              end
            end
          '';

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

          theme = {
            enable = true;
            name = "base16";
            base16-colors = filterAttrs (n: _: builtins.match "base0[0-9A-F]" n != null)
              config.lib.stylix.colors.withHashtag;
          };

          statusline = {
            lualine = {
              enable = true;
              setupOpts.options.theme = "base16";
            };
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

            presets = {
              tailwindcss-language-server.enable = true;
            };
          };

          languages = {
            enableDAP = true;
            enableTreesitter = true;
            enableFormat = true;

            nix.enable = true;
            lua.enable = true;
            typescript.enable = true;
            tsx.enable = true;
            clang.enable = true;
            python.enable = true;
            rust.enable = true;
            go.enable = true;
            markdown.enable = true;
            html.enable = true;
            css.enable = true;
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
