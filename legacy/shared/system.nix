{ config, lib, pkgs, ... }:

{
  imports = [
    ./sops/system.nix
    ./stylix.nix
    ./ghostty.nix
    ./apps/slack.nix
    ./apps/browsers.nix
    ./apps/obsidian.nix
    ./apps/todoist.nix
    ./docker.nix
  ];
}
