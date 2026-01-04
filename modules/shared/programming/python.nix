{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.languages.python;
in
{
  options.userSettings.programming.languages.python.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Python programming environment.";
  };

  config = mkIf cfg.enable {
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
