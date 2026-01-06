{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/shared/system.nix
  ];

  # Note: systemSettings can be added here when darwin-specific settings are needed

  users.users.${settings.user.name} = {
    name = "${settings.user.name}";
    home = "/Users/${settings.user.name}";
    isHidden = false;
    shell = pkgs.zsh;
  };
}
