{ config, pkgs, inputs, settings, ... }:

{
  imports = [
    ./picker.nix
  ];

  programs.nvf.settings.vim = {
    utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        input = {
          enable = true;
        };
        git = {
          enable = true;
        };
        gh = {
          enable = true;
        };
      };
    };
  };
}
