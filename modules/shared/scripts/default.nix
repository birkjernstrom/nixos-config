{ pkgs, lib, ... }:

let
  t = pkgs.writeScriptBin "t" (builtins.readFile ./t.sh);
in
{
  imports = [
    ./email-cli
  ];

  home.packages = [
    t
  ];
}
