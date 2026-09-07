{ config, lib, ... }:

with lib; let
  cfg = config.systemSettings.primo;
in
{
  options.systemSettings.primo.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable the Primo MDM agent (system-level)";
  };

  # Primo's Linux agent is Fleet + osquery -- their installer is an unmodified
  # `fleet-osquery` nfpm package from fleetdm.com -- so rather than unpacking
  # their .pkg.tar.zst we use the nixpkgs packaging, which carries NixOS-specific
  # patches and a NixOS VM test.
  config = mkIf cfg.enable {
    sops.secrets.primo-enroll-secret = { };

    # Orbit shells out via `sudo -n -i -u <user>` to launch fleet-desktop (and
    # the enrollment SSO browser). sudo lives in /run/wrappers/bin, which is not
    # on the unit's default PATH, so without this those launches fail.
    systemd.services.orbit.path = [ "/run/wrappers" ];

    services.orbit = {
      enable = true;
      fleetUrl = "https://polar.mdm.getprimo.com";
      enrollSecretPath = config.sops.secrets.primo-enroll-secret.path;

      # Both match what Primo's own package ships in /etc/default/orbit.
      desktop.enable = true;
      enableScripts = true;

      # Orbit's self-updater fetches FHS-linked binaries into /opt/orbit, which
      # cannot execute here, so services.orbit sets ORBIT_DISABLE_UPDATES=true.
      # The agent is updated by bumping nixpkgs, not by orbit updating itself.
    };
  };
}
