{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.cli.direnv;
in
{
  options.userSettings.cli.direnv.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable direnv with nix-direnv for automatic flake dev shells.";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = config.userSettings.cli.zsh.enable;
      config.global = {
        hide_env_diff = true;
        warn_timeout = "30s";
      };
    };

    programs.git.ignores = [ ".direnv/" ];
  };
}
