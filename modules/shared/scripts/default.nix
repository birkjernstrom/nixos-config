{ pkgs, ... }:

let
  t = pkgs.writeScriptBin "t" (builtins.readFile ./t.sh);
in
{
  home.packages = [
    t
  ];
}
