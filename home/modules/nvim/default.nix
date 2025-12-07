{ config, pkgs, inputs, settings, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./keymaps.nix
    ./telescope.nix
    ./neotree.nix
  ];

  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        vimAlias = true;
        lsp = {
          enable = true;
        };
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        statusline.lualine.enable = true;
        autocomplete.nvim-cmp.enable = true;

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
    };
  };
}
