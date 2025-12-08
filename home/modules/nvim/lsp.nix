{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      mappings = {
        renameSymbol = "<leader>cr";
        codeAction = "<leader>ca";
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
}
