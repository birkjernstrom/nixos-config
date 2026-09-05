# TEMPORARY migration shim.
#
# Re-exports the two system configurations exactly as the old flake.nix did, so
# that adding flake-parts + import-tree is a provable no-op: the toplevel
# derivation must not change. This file is replaced by per-host files under
# modules/hosts/ in the next step, and lib/kit.nix goes away with it.
{ inputs, ... }:

let
  kit = import ../lib/kit.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.framework = kit.mkSystem "framework" {
    system = "x86_64-linux";
    user = "birk";
    isDarwin = false;
  };

  flake.darwinConfigurations.mbp = kit.mkSystem "mbp" {
    system = "aarch64-darwin";
    user = "birk";
    isDarwin = true;
  };
}
