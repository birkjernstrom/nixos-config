{ config, pkgs, lib, ... }:

let
  user = "birk";
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs; };
  sharedPrograms = import ../shared/home/programs { inherit config pkgs lib; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    stateVersion = "24.05"; # Please read the comment before changing.
    username = "${user}";
    homeDirectory = "/home/${user}";
    file = lib.mkMerge [
      sharedFiles
    ];
    packages = pkgs.callPackage ./packages.nix {};
  };

  programs = lib.mkMerge [
    sharedPrograms
    {
      wezterm.enable = true;
    }
  ];
}
