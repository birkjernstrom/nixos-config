{ config, pkgs, lib, ... }:

with lib; let
  feat = config.features.programming.languages.rust;
in
{
  options.features.programming.languages.rust.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Rust programming environment.";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      rustup
    ];

    home.sessionPath = [ "$HOME/.cargo/bin" ];

    programs = {};
  };
}
