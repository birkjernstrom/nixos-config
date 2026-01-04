{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.languages.rust;
in
{
  options.userSettings.programming.languages.rust.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Rust programming environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustup
    ];

    home.sessionPath = [ "$HOME/.cargo/bin" ];

    programs = {};
  };
}
