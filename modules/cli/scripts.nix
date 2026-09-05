# Small personal shell scripts, installed as real binaries on PATH.
#
# _t.sh is prefixed so import-tree skips it - it is a shell script, not a
# module, and every path containing `_` is ignored.
{
  flake.modules.homeManager.base = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeScriptBin "t" (builtins.readFile ./_t.sh))
    ];
  };
}
