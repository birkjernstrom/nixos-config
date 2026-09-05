# MacBook Pro (nix-darwin, aarch64-darwin).
#
# The macOS system settings themselves live in modules/darwin.nix, since they
# apply to any darwin host rather than this one specifically.
{ config, inputs, ... }:

{
  flake.modules.darwin.mbp = { pkgs, ... }: {
    users.users.birk = {
      name = "birk";
      home = "/Users/birk";
      isHidden = false;
      shell = pkgs.zsh;
    };
  };

  flake.darwinConfigurations.mbp = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };

    modules = with config.flake.modules.darwin; [
      base
      gui-apps
      mbp

      inputs.home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };

        home-manager.users.birk = {
          imports = with config.flake.modules.homeManager; [
            base
            dev
            gui-apps
          ];

          home.stateVersion = "24.05";
        };
      }

      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          user = "birk";
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
      ({ config, ... }: {
        homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
      })
    ];
  };
}
