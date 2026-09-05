# Framework 16 (NixOS, x86_64-linux).
#
# Still assembled from the legacy/ module tree via the old `settings` /
# `isDarwin` specialArgs. Those go away once the leaf modules are converted to
# `flake.modules.*`; this step only moves host assembly out of lib/kit.nix.
{ config, inputs, ... }:

let
  hostSettings = import ../../hosts/framework/settings.nix;

  settings = {
    user = hostSettings.user // { name = "birk"; };
    system = hostSettings.system or { };
  };

  specialArgs = {
    inherit inputs settings;
    isDarwin = false;
  };
in
{
  flake.nixosConfigurations.framework = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    inherit specialArgs;

    modules = [
      config.flake.modules.nixos.base
      ../../hosts/framework/configuration.nix
      inputs.stylix.nixosModules.stylix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.birk.imports = [
          config.flake.modules.homeManager.base
          ../../hosts/framework/home.nix
        ];
        home-manager.extraSpecialArgs = specialArgs;
      }
    ];
  };
}
