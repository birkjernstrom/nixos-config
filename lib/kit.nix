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
    pkgs = import inputs.nixpkgs { inherit system; };

    # Load the selected theme
    theme = import ../themes { inherit pkgs; };

    # Load host-specific settings
    hostSettings = import ../hosts/${name}/settings.nix;

    settings = {
      user = hostSettings.user // { name = user; };
      system = hostSettings.system or {};
    };

    specialArgs = {
      inherit inputs;
      inherit settings;
      inherit isDarwin;
      inherit theme;
    };

    configuration = ../hosts/${name}/configuration.nix;
    home = ../hosts/${name}/home.nix;

    # NixOS vs nix-darwin functions
    systemFunc = if isDarwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
    home-manager = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

    # Stylix modules for system and home-manager
    stylixModule = if isDarwin then inputs.stylix.darwinModules.stylix else inputs.stylix.nixosModules.stylix;
  in systemFunc rec {
    inherit system;
    inherit specialArgs;

    modules = [
      configuration
      stylixModule
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
        };
      }
      ({config, ...}: {
        homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
      })
    ] else []);
  };
}
