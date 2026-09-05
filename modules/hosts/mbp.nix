# MacBook Pro (nix-darwin, aarch64-darwin).
#
# See modules/hosts/framework.nix - same temporary shape, plus the homebrew
# wiring that only this host needs.
{ config, inputs, ... }:

let
  hostSettings = import ../../hosts/mbp/settings.nix;

  settings = {
    user = hostSettings.user // { name = "birk"; };
    system = hostSettings.system or { };
  };

  specialArgs = {
    inherit inputs settings;
    isDarwin = true;
  };
in
{
  flake.darwinConfigurations.mbp = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    inherit specialArgs;

    modules = [
      config.flake.modules.darwin.base
      ../../hosts/mbp/configuration.nix
      inputs.stylix.darwinModules.stylix
      inputs.home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.birk.imports = [
          config.flake.modules.homeManager.base
          ../../hosts/mbp/home.nix
        ];
        home-manager.extraSpecialArgs = specialArgs;
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
