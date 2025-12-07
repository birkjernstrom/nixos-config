{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim.assistant = {
    copilot = {
      enable = true;
    };
  };
}
