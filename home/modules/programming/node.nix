{ config, lib, pkgs, ... }:

with lib; let
  feat = config.features.programming.node;
in 
{
  options.features.programming.node.enable = mkEnableOption "enable Node programming";

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      nodejs_20
      corepack
    ];

    programs = {};
  };
}
