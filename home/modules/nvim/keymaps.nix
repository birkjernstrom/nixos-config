{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim = {
    keymaps = [
      # Keep cursor in same place when using J
      {
        mode = "n";
        key = "J";
        action = "mzJ`z";
      }
      # Quickfix shortcuts
      {
        mode = "n";
        key = "]q";
        action = ":cnext<CR>";
      }
      {
        mode = "n";
        key = "[q";
        action = ":cprev<CR>";
      }
      # Page jump & search stays focused in center of buffer
      {
        mode = "n";
        key = "<C-d>";
        action = "<C-d>zz";
      }
      {
        mode = "n";
        key = "<C-u>";
        action = "<C-u>zz";
      }
      {
        mode = "n";
        key = "n";
        action = "nzzzv";
      }
      {
        mode = "n";
        key = "N";
        action = "Nzzzv";
      }
      # Move selection up || down
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
      }
    ];
  };
}
