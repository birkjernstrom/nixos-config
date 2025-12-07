{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim = {
    filetree.neo-tree = {
      enable = true;
    };
    keymaps = [
      # Keep cursor in same place when using J
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree toggle reveal float<CR>";
      }
      {
        mode = "n";
        key = "<leader><tab>";
        action = ":Neotree toggle reveal left<CR>";
      }
    ];
  };
}
