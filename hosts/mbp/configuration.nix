{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    ../../legacy/darwin/system.nix
    ../../legacy/shared/system.nix
  ];

  # Note: systemSettings can be added here when darwin-specific settings are needed

  users.users.${settings.user.name} = {
    name = "${settings.user.name}";
    home = "/Users/${settings.user.name}";
    isHidden = false;
    shell = pkgs.zsh;
  };
}
