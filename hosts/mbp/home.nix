{ config, pkgs, lib, inputs, settings, isDarwin, ... }:

{
  imports = [
    ../../home
  ];

  config.features = {
    cli = {
      zsh.enable = true;
      git.enable = true;
      tmux.enable = true;
    };
    programming = {
      python.enable = true;
      typescript.enable = true;
      go.enable = true;
    };
  };
}
