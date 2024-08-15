{ config, pkgs, lib, home-manager, nixpkgs-stable, settings, isDarwin, ... }:

let
  inherit settings;
  darwinServices = import ./services { inherit config pkgs lib settings isDarwin; };
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs settings isDarwin; };
  sharedPrograms = import ../shared/home/programs { inherit config pkgs lib settings isDarwin; };
in
{
  users.users.${settings.username} = {
    name = "${settings.username}";
    home = "/Users/${settings.username}";
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
    users.${settings.username} = { pkgs, config, lib, ... }:{
      home = {
        packages = pkgs.callPackage ./packages.nix {
          inherit pkgs;
          inherit nixpkgs-stable;
        };
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
