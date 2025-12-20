{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.python;
in
{
  options.features.programming.python.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Python programming environment.";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      pyenv
      poetry
      uv
      python314
    ];

    programs = {
      pyenv = {
        enable = true;
        enableZshIntegration = true;
      };

      poetry.enable = true;
    };
  };
}
