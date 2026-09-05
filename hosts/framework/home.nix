{ config, pkgs, lib, inputs, settings, isDarwin, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    ../../legacy/nixos/home.nix
    ../../legacy/shared/home.nix
  ];

  config = {
    # Apply user settings from settings.nix
    userSettings = hostSettings.user;

    home.stateVersion = "24.05";

    home.packages = with pkgs; [
      google-chrome
    ];
  };
}
