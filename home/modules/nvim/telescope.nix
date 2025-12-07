{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim.telescope = {
    enable = true;
    mappings = {
      findFiles = "<leader><space>";
      liveGrep = "<leader>fg";
      lspDocumentSymbols = "<leader>fs";
      lspReferences = "gr";
      lspDefinitions = "gd";
      lspImplementations = "gi";
      lspTypeDefinitions = "gt";
      buffers = "<leader>fb";
      diagnostics = "<leader>fd";
      gitFiles = "<leader>gf";
      helpTags = "<leader>fh";
    };
    extensions = [
      {
        name = "fzf";
        packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
        setup = {
          fzf = {
            fuzzy = true;
            override_generic_sorter = true; # override the generic sorter
            override_file_sorter = true; # override the file sorter
            case_mode = "smart_case";
          };
        };
      }
    ];
    setupOpts.defaults = {
      file_ignore_patterns = [
        "node_modules"
        "%.git/"
        "dist/"
        "build/"
        "target/"
        "result/"
      ];
      layout_config.horizontal.prompt_position = "bottom";
    };
  };
}
