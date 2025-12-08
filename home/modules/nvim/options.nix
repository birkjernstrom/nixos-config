{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim = {
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
  };
}
