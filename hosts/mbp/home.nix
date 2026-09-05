{ config, pkgs, lib, inputs, settings, isDarwin, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    ../../legacy/darwin/home.nix
    ../../legacy/shared/home.nix
  ];

  config = {
    # Apply user settings from settings.nix
    userSettings = hostSettings.user;

    home.stateVersion = "24.05";
  };
}
