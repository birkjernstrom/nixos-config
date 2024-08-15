{ config, pkgs, nixpkgs-stable, lib, settings, isDarwin, ... }:

let
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs; };
  sharedPrograms = import ../shared/home/programs { inherit config pkgs lib; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    stateVersion = "24.05"; # Please read the comment before changing.
    username = "${settings.username}";
    homeDirectory = "/home/${user}";
    file = lib.mkMerge [
      sharedFiles
    ];
    packages = pkgs.callPackage ./packages.nix {
      inherit pkgs;
      inherit nixpkgs-stable;
    };
  };

  programs = lib.mkMerge [
    sharedPrograms
    {
      wezterm.enable = true;
    }
  ];
}
