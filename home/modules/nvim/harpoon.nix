{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim.navigation.harpoon = {
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
}
