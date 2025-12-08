{ config, pkgs, inputs, settings, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./keymaps.nix
    ./lsp.nix
    ./snacks
    ./ai.nix
    ./harpoon.nix
    ./neotree.nix
  ];

  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        vimAlias = true;
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        statusline.lualine.enable = true;
        autocomplete.nvim-cmp.enable = true;
        diagnostics.nvim-lint.enable = true;
      };
    };
  };
}
