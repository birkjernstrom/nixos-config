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

  # gtksourceview 5.21.0's test-buffer aborts (SIGABRT) and Hydra has no build
  # of it to substitute. Drop once nixpkgs ships a cached build.
  nixpkgs.overlays = [
    (final: prev: {
      gtksourceview5 = prev.gtksourceview5.overrideAttrs { doCheck = false; };
    })
  ];
}
