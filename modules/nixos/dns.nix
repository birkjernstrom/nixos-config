{ lib, ... }:

{
  # systemd-resolved owns DNS: Cloudflare globally, never DHCP-supplied
  # servers. Tailscale (accept-dns, see tailscale.nix) only adds split routes
  # (ts.net etc.) on tailscale0 as long as "Override Local DNS" is off.
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ ];
  };

  # resolved.nix sets dns = "systemd-resolved", which would hand the DHCP
  # servers to resolved as per-link DNS on wlan0.
  networking.networkmanager.dns = lib.mkForce "none";
  networking.networkmanager.settings.main.systemd-resolved = false;
}
