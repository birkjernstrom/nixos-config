{ config, pkgs, lib, home-manager, ... }:

let
  user = "birk";
  darwinServices = import ./services { inherit config pkgs lib; };
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs; };
  sharedPrograms = import ../shared/home/programs { inherit config pkgs lib; };
in
{
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    masApps = {
      # Mac App Store Installations
      # "1password" = 1333542190;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
        ];
        stateVersion = "24.05";
      };


      programs = lib.mkMerge [
        sharedPrograms
      ];

    };
  };

  services = darwinServices;
}
