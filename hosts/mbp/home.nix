{ config, ... }:

{
  imports = [
    ../../home
  ];

  config.features = {
    cli = {
      git.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    programming = {
      python.enable = true;
      node.enable = true;
    };
  };
}
