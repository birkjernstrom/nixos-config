{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts
    ./nix.nix
    ./stylix.nix
    ./hyprland/system.nix
    ./primo.nix
    ./clamav.nix
    ./dns.nix
    ./fwupd.nix
    ./greetd.nix
    ./tailscale.nix
    ./ssh.nix
    ./steam.nix
    ./agents/system.nix
  ];
}
