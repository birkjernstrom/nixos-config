{ config, lib, ... }:

with lib; let
  cfg = config.systemSettings.clamav;
in
{
  options.systemSettings.clamav = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable ClamAV antivirus (system-level)";
    };

    scanDirectories = mkOption {
      type = types.listOf types.str;
      default = [ "/home" "/etc" "/tmp" "/var/tmp" "/var/lib" ];
      description = ''
        Directories the nightly scan walks. This is the nixpkgs default list.

        /nix/store is deliberately absent: it is tens of gigabytes of packages
        whose integrity is already guaranteed by their hashes, so scanning it
        costs hours and proves nothing.
      '';
    };

    onAccess.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Real-time on-access scanning (clamonacc), which intercepts file opens
        through fanotify.

        The cost lands squarely on this machine's normal workload: a nix build
        or an npm install opens hundreds of thousands of small files, and each
        one becomes a synchronous round trip to clamd. Enable it only when a
        compliance control actually requires the clamonacc unit to be running --
        Fleet policy 17 ("Linux protection check") does.
      '';
    };

    onAccess.includePaths = mkOption {
      type = types.listOf types.str;
      default = [ "/home" ];
      description = ''
        Paths clamonacc watches. This is not merely a tuning knob: clamonacc
        refuses to start when clamd.conf carries no OnAccessIncludePath at all,
        and a clamonacc that exits immediately fails the very policy that on-access
        scanning was switched on to satisfy.

        Kept to /home deliberately. Watching /nix/store would be both pointless
        (contents are hash-verified and read-only) and ruinous, since every
        binary the system executes lives there.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.clamav = {
      daemon.enable = true;

      # Keeps the signature database from going stale. Note that enabling this
      # is what generates /etc/clamav/freshclam.conf; the unit it also generates
      # is replaced below.
      updater.enable = true;

      scanner = {
        enable = true;
        inherit (cfg) scanDirectories;
      };

      clamonacc.enable = cfg.onAccess.enable;
    };

    # The tailnet's `fleetPolicy:antimalware` assertion is fed by Fleet policy
    # 17, "Linux protection check". That policy does not look at processes or at
    # signature age -- it asserts on systemd unit state:
    #
    #   COUNT(DISTINCT id) FROM systemd_units WHERE id IN (
    #     'clamav-daemon.service', 'clamav-clamonacc.service',
    #     'clamav-freshclam.timer'
    #   ) AND load_state = 'loaded' AND active_state = 'active'   -- must be 3
    #   AND NOT EXISTS (... id = 'clamav-freshclam.service' AND
    #                       active_state = 'failed')
    #
    # So all three units have to exist and be active, and upstream's shapes are
    # exactly what it expects: the timer stays a timer, and freshclam stays the
    # Type=oneshot unit behind it. Converting freshclam into a resident daemon
    # (which is what Fleet's *stock* antivirus policy would want, since that one
    # greps the process table) removes clamav-freshclam.timer and fails this
    # policy instead. Leave the upstream units alone.

    # Both long-running units named above have to be active at the moment
    # osquery samples, and upstream sets no Restart= on either. A crash would
    # otherwise sit there until somebody noticed -- which is precisely the state
    # the policy exists to detect, so it should self-heal rather than latch.
    systemd.services.clamav-daemon.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };

    systemd.services.clamav-clamonacc.serviceConfig = mkIf cfg.onAccess.enable {
      Restart = "on-failure";
      RestartSec = "30s";
    };

    # freshclam's timer is a required unit for the policy, so it must not be
    # disabled -- and Persistent matters for the usual laptop reason: a missed
    # OnCalendar run is dropped rather than deferred, so every hourly update
    # landing inside a closed lid was simply lost.
    systemd.timers.clamav-freshclam.timerConfig.Persistent = true;

    # The scanner timer stays a timer -- a nightly scan genuinely is a oneshot.
    # It does need Persistent, though: without it the 04:00 run is skipped
    # outright when the lid is shut at 04:00, rather than deferred, so the
    # evidence trail gets an entry for every day the machine happened to be
    # awake at 4am instead of every day it was used.
    #
    # The delay keeps the catch-up run from starting the instant the lid opens,
    # which is exactly when the machine is least able to spare the cores.
    systemd.timers.clamdscan.timerConfig = {
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    services.clamav.daemon.settings = mkIf cfg.onAccess.enable {
      OnAccessIncludePath = cfg.onAccess.includePaths;

      # Notify-only. With prevention on, clamd holds every fanotify permission
      # event until it has finished scanning, so a clamd that is slow, wedged or
      # simply throttled stops being an antivirus and starts being a filesystem
      # outage. The policy only asks that clamonacc be running.
      OnAccessPrevention = false;
    };

    # Everything ClamAV runs is already collected into this slice upstream.
    # Capping it here rather than on the individual units means the nightly scan
    # cannot monopolise the machine when it catches up mid-morning.
    #
    # CPUQuota is a share of a *single* core, so the 50% that comfortably fits a
    # background scan would put every file open in /home behind half a core once
    # on-access scanning is live. The scan is throttled by CPUWeight either way;
    # the quota is what would turn latency into a stall.
    systemd.slices.system-clamav.sliceConfig = {
      CPUQuota = if cfg.onAccess.enable then "400%" else "50%";
      CPUWeight = 20;
      IOWeight = 20;
    };
  };
}
