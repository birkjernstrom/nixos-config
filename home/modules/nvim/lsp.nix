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
