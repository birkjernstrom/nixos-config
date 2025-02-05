{
  description = "Birk NixOS & Nix Darwin Configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-22.05";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ############################################################################
    # SOPS
    ############################################################################

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/birkjernstrom/secrets.git?ref=main&shallow=1";
      flake = false;
    };

    ############################################################################
    # DARWIN
    ############################################################################

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
    homebrew-speakeasy = {
      url = "github:speakeasy-api/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-stable, home-manager, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:
    let
      kit = import ./lib/kit.nix { inherit inputs; };
    in {

    # Development server
    nixosConfigurations.burken = kit.mkSystem "burken" {
      system = "aarch64-linux";
      user = "birk";
      isDarwin = false;
    };

    darwinConfigurations.mbp = kit.mkSystem "mbp" {
      system = "aarch64-darwin";
      user = "birk";
      isDarwin = true;
    };
  };
}
