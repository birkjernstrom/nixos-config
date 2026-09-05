{
  description = "Birk NixOS & Nix Darwin Configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    ############################################################################
    # DENDRITIC
    #
    # flake-parts provides the top-level module system; import-tree turns every
    # file under ./modules into one of its modules. See modules/meta.nix.
    ############################################################################

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

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

  # The only entry point. Every other .nix file under ./modules is a
  # flake-parts module, imported automatically.
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
