{ lib, pkgs, ... }:

let
  # Captive portals only answer DNS via their own resolver until you log in.
  captive = pkgs.writeShellApplication {
    name = "captive";
    runtimeInputs = with pkgs; [ networkmanager systemd curl gawk gnugrep coreutils xdg-utils ];
    text = ''
      dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" { print $1; exit }')
      [ -n "$dev" ] || { echo "no wifi device found" >&2; exit 1; }

      mapfile -t servers < <(nmcli -g IP4.DNS device show "$dev" | awk -F'|' '{ for (i = 1; i <= NF; i++) { gsub(/[[:space:]]/, "", $i); if ($i != "") print $i } }')
      [ "''${#servers[@]}" -gt 0 ] || { echo "no DHCP DNS on $dev" >&2; exit 1; }

      revert() { sudo resolvectl revert "$dev"; echo "DNS on $dev reverted to Cloudflare"; }
      trap revert EXIT

      sudo resolvectl dns "$dev" "''${servers[@]}"
      sudo resolvectl domain "$dev" '~.'
      sudo resolvectl default-route "$dev" true
      sudo resolvectl flush-caches
      echo "Using ''${servers[*]} on $dev until you are online"

      probe=http://connectivitycheck.gstatic.com/generate_204
      online() { [ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' "$probe")" = 204 ]; }

      portal=$(curl -s -m 5 -o /dev/null -w '%{redirect_url}' "$probe" || true)
      xdg-open "''${portal:-http://httpforever.com}" >/dev/null 2>&1 &

      until online; do
        sleep 3
      done
      echo "Portal passed"
    '';
  };
in
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

  environment.systemPackages = [ captive ];
}
