{ config, pkgs, inputs, settings, ... }:
let
  secretspath = builtins.toString inputs.config-private;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/key.txt";

    secrets = {
      anthropic = {};
    };
  };
}
