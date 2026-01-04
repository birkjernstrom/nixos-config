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
    userSettings = hostSettings.user;

    home.stateVersion = "24.05";

    home.packages = with pkgs; [
      ghostty
      google-chrome
      fastfetch
    ];
    programs.ghostty.enable = true;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        text-scaling-factor = 1.0;
      };

      "org/gnome/desktop/input-sources" = {
        xkb-options = [
          "ctrl:nocaps"
        ];
      };

      "org/gnome/desktop/peripherals/keyboard" = {
        delay = 200;
        repeat-interval = 10;
      };
    };
  };
}
