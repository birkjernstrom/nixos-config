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
    ./desktop.nix
    ./fwupd.nix
    ./pki.nix
    ./greetd.nix
    ./tailscale.nix
    ./ssh.nix
    ./steam.nix
    ./agents/system.nix
  ];
}
