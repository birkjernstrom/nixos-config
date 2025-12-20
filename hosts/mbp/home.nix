{ config, pkgs, lib, inputs, settings, isDarwin, ... }:

{
  imports = [
    ../../home
  ];

  config.features = {
    cli = {
      core.enable = true;
      zsh.enable = true;
      git.enable = true;
      tmux.enable = true;
      nvim.enable = true;
    };
    programming = {
      languages = {
        python.enable = true;
        typescript.enable = true;
        go.enable = true;
      };

      ai.enable = true;
      tools.enable = true;
    };
  };
}
