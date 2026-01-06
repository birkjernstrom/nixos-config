{ config, lib, pkgs, ... }:

{
  imports = [
    ./sops/system.nix
    ../apps/slack.nix
  ];
}
