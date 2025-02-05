{ config, lib, pkgs, ... }:

with lib; let
  feat = config.features.programming.python;
in 
{
  options.features.programming.python.enable = mkEnableOption "enable Python programming";

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      pyenv
      poetry
      uv
      python313
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
