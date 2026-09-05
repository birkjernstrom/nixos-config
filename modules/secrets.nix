# sops-nix: age-encrypted secrets, checked into the private config-private
# input rather than this repo.
#
# The same secrets file is decrypted twice - once by the system and once inside
# the home-manager evaluation - because the two have separate sops modules.
# Only home-manager actually declares a secret today (`anthropic`, read by zsh).
{ inputs, ... }:

let
  secretspath = builtins.toString inputs.config-private;

  system = { pkgs, config, ... }: {
    environment.systemPackages = [ pkgs.sops ];

    sops = {
      defaultSopsFile = "${secretspath}/secrets.yaml";
      age.keyFile = "${config.users.users.birk.home}/.config/sops/age/key.txt";
      secrets = { };
    };
  };
in
{
  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops system ];
  };

  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.sops system ];
  };

  flake.modules.homeManager.base = { config, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops = {
      defaultSopsFile = "${secretspath}/secrets.yaml";
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/key.txt";

      secrets = {
        anthropic = { };
      };
    };
  };
}
