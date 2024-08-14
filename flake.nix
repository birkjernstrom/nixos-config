{
  description = "Birk NixOS & Nix Darwing Configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:
    let
      lib = nixpkgs.lib;
      user = "birk";
    in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/desktop-home.nix
	];
      };
      framework-amd-7040 = lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/framework-amd-7040.nix
	];
      };
      utm-aarch64 = lib.nixosSystem {
        system = "aarch64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/utm-aarch64.nix
	];
      };
    };
    darwinConfigurations = {
      darwin = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew {
            nix-homebrew = {
              inherit user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
              autoMigrate = true;
            };
          }
          ./hosts/darwin
        ];
      };
    };
  };
}
