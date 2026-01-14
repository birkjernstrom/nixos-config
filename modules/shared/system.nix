{ config, lib, pkgs, ... }:

{
  imports = [
    ./sops/system.nix
    ./ghostty.nix
    ./apps/slack.nix
    ./apps/browsers.nix
    ./docker.nix
  ];
}
