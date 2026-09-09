{ config, lib, settings, ... }:

with lib; let
  cfg = config.systemSettings.tailscale;
in
{
  options.systemSettings.tailscale.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Tailscale (system-level)";
  };

  # Primo cannot deploy this for us: Fleet-Maintained Apps are macOS/Windows
  # only, and its Linux path (.deb/.rpm/.sh/.tar.gz) has nothing that works
  # against a read-only /nix/store. So we install declaratively and let Primo
  # observe the result via osquery instead of managing it.
  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;

      # Reaching work subnets is the point of joining, and that needs reverse
      # path filtering set to loose. Note this does NOT enable IP forwarding --
      # that is "server", for advertising routes, which this machine does not.
      useRoutingFeatures = "client";

      # Without an operator, `tailscale up`/`down` are root-only, and the bar
      # module could not toggle the tailnet without a password prompt. This
      # hands the daemon's local API to the desktop user, which is what the
      # macOS and Windows clients do implicitly.
      #
      # Posture checking opts the node into reporting its identity (serial
      # numbers, MAC addresses) to the tailnet. Tailscale requires it for any
      # device-posture integration, and without it the Primo/Fleet integration
      # has nothing to correlate this node against - which is why the tailnet's
      # `fleet:present` assertion read "not set" rather than false.
      extraSetFlags = [
        "--operator=${settings.user.name}"
        "--posture-checking=true"
      ];

      # Seals tailscaled's state file to the TPM (/dev/tpm0) instead of leaving
      # it plaintext on disk, which is what the tailnet's
      # `node:tsStateEncrypted == true` assertion is checking.
      extraDaemonFlags = [ "--encrypt-state" ];
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
