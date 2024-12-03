{ inputs, ... }:

{
  # Credit to @mitchellh
  #
  # Modified version of his `mksystem`
  # https://github.com/mitchellh/nixos-config/blob/main/lib/mksystem.nix
  mkSystem = name: {
    system,
    user,
    isDarwin ? false,
  }:
  let
    settings = {
      inherit user;
    };

    specialArgs = {
      inherit inputs;
      inherit settings;
      inherit isDarwin;
    };

    configuration = ../hosts/${name}/configuration.nix;
    home = ../hosts/${name}/home.nix;

    # NixOS vs nix-darwin functions
    systemFunc = if isDarwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
    home-manager = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  in systemFunc rec {
    inherit system;
    inherit specialArgs;

    modules = [
      configuration
      home-manager.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = home;
        home-manager.extraSpecialArgs = specialArgs;
      }
    ] ++ (if isDarwin then [
      inputs.nix-homebrew.darwinModules.nix-homebrew {
        nix-homebrew = {
          inherit user;
          enable = true;
          taps = {
            "homebrew/homebrew-core" = inputs.homebrew-core;
            "homebrew/homebrew-cask" = inputs.homebrew-cask;
            "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
            "speakeasy-api/homebrew-tap" = inputs.homebrew-speakeasy;
          };
          mutableTaps = false;
          autoMigrate = true;
        };
      }
    ] else []);
  };
}
