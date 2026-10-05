{ config, lib, settings, ... }:

with lib; let
  cfg = config.systemSettings.ssh;
in
{
  options.systemSettings.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the OpenSSH server, key-only and reachable over the tailnet only";
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOl5CIXYEY780jgdbBmbmkIjuhEPO5WiTvnskXXYN0pR"
      ];
      description = "Public keys allowed to log in as the primary user";
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      # Still reachable via tailscale0, which tailscale.nix marks as trusted.
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    users.users.${settings.user.name}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
