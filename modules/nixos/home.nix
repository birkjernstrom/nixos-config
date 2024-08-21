{ config, pkgs, ... }:

{
  imports = [
    ../shared/home/files.nix
    ../shared/home/programs
  ];

  config = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home = {
      stateVersion = "24.05"; # Please read the comment before changing.
      packages = with pkgs; [
        # NixOS specific packages below

        # Build tools
        gnumake
        gcc
      ];
    };
  };
}
