{ config, pkgs, inputs, settings, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  programs.nvf = {
    enable = true;

    settings = {
      vim.vimAlias = true;
      vim.lsp = {
        enable = true;
      };
      vim.theme = {
        enable = true;
	name = "catppuccin";
	style = "mocha";
      };
    };
  };
}
