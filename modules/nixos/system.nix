{ config, lib, pkgs, ... }:

{
  imports = [
    ./fonts
    ./nix.nix
    ./stylix.nix
    ./hyprland/system.nix
    ./noctalia
    ./primo.nix
    ./clamav.nix
    ./dns.nix
    ./fwupd.nix
    ./tailscale.nix
    ./ssh.nix
    ./steam.nix
    ./agents/system.nix
  ];
}
