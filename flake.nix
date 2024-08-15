{
  description = "Birk NixOS & Nix Darwing Configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-22.05";

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

  outputs = inputs @ { self, nixpkgs, nixpkgs-stable, home-manager, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:
    let
      lib = nixpkgs.lib;
      settings = {
        username = "birk";
      };
    in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${settings.username} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/desktop-home.nix
	];
        specialArgs = {
          inherit settings;
          inherit nixpkgs-stable;
          isDarwin = false;
        };
      };
      framework-amd-7040 = lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${settings.username} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/framework-amd-7040.nix
	];
        specialArgs = {
          inherit settings;
          inherit nixpkgs-stable;
          isDarwin = false;
        };
      };
      utm-aarch64 = lib.nixosSystem {
        system = "aarch64-linux";
	modules = [
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${settings.username} = import ./modules/nixos/home.nix;
            };
          }
	  ./hosts/nixos/utm-aarch64.nix
	];
        specialArgs = {
          inherit settings;
          inherit nixpkgs-stable;
          isDarwin = false;
        };
      };
    };
    darwinConfigurations = {
      darwin = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew {
            nix-homebrew = {
              user = settings.username;
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
        specialArgs = {
          inherit settings;
          inherit nixpkgs-stable;
          isDarwin = true;
        };
      };
    };
  };
}
