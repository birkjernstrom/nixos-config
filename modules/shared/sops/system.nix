{ config, pkgs, inputs, settings, isDarwin, ... }:
let
  secretspath = builtins.toString inputs.config-private;
  sopsmodule = if isDarwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops;
in
{
  imports = [
    sopsmodule
  ];

  environment.systemPackages = with pkgs; [
    sops
  ];

  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    age.keyFile = "${config.users.users.${settings.user}.home}/.config/sops/age/key.txt";

    secrets = {};
  };
}
