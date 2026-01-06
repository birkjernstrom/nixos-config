{ config, pkgs, lib, inputs, settings, isDarwin, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    ../../modules/nixos/home.nix
    ../../modules/shared/home.nix
  ];

  config = {
    # Apply user settings from settings.nix
    userSettings = hostSettings.user // {
      terminal.ghostty.enable = true;
    };

    home.stateVersion = "24.05";

    home.packages = with pkgs; [
      ghostty
      google-chrome
      fastfetch
      btop
    ];
  };
}
