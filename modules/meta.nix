# Top-level configuration for the flake itself.
#
# Every other file under ./modules is a flake-parts module, auto-imported by
# import-tree (see flake.nix). import-tree skips any path containing `_`, which
# is how non-module files (package expressions, generated hardware config) stay
# out of the tree.
{ inputs, ... }:

{
  # `flake.modules.<class>.<name>` is NOT a flake-parts builtin - it lives in
  # flake-parts' extras and has to be imported. Its type is
  # `lazyAttrsOf (lazyAttrsOf deferredModule)`, so the same name defined across
  # many files merges into one module. Without this import, flake outputs fall
  # back to a `unique` freeform type and a second definition is an error.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" "aarch64-darwin" ];
}
