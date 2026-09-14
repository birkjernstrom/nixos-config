{
  description = "Birk NixOS & Nix Darwin Configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to a tag rather than a branch: Noctalia is the whole desktop
    # shell, and v5 is a young rewrite - an unattended `nix flake update`
    # pulling in a shell that no longer starts is not a good trade. Bump this
    # deliberately. nixpkgs also carries a `noctalia` package and a matching
    # programs.noctalia module, but its pin lags a release or two behind; the
    # flake's own module disables the nixpkgs one so the two never collide.
    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ############################################################################
    # SOPS
    ############################################################################

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    config-private = {
      url = "git+ssh://git@github.com/birkjernstrom/config-private.git?ref=main&shallow=1";
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

  outputs = inputs @ { self, nixpkgs, nixpkgs-stable, home-manager, nvf, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ... }:
    let
      kit = import ./lib/kit.nix { inherit inputs; };
    in {

    darwinConfigurations.mbp = kit.mkSystem "mbp" {
      system = "aarch64-darwin";
      user = "birk";
      isDarwin = true;
    };

    nixosConfigurations.framework = kit.mkSystem "framework" {
      system = "x86_64-linux";
      user = "birk";
      isDarwin = false;
    };
  };
}
