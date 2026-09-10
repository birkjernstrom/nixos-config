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
        Real-time on-access scanning (clamonacc), which intercepts every file
        open through fanotify.

        Off by default because the cost lands squarely on this machine's normal
        workload: a nix build or an npm install opens hundreds of thousands of
        small files, and each one becomes a synchronous round trip to clamd.
        Turn it on only if the compliance control specifically says "real-time"
        and the scheduled scan below is not accepted as an alternative.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.clamav = {
      # clamd is the piece any posture check can actually observe. freshclam and
      # clamdscan are oneshot units that exit as soon as their work is done, so
      # at a randomly sampled moment clamd is the only ClamAV process alive.
      daemon.enable = true;

      # freshclam, on an hourly timer, is what keeps the signature database from
      # going stale -- the single thing an antivirus control is usually written
      # against ("signatures no older than N days").
      updater.enable = true;

      scanner = {
        enable = true;
        inherit (cfg) scanDirectories;
      };

      clamonacc.enable = cfg.onAccess.enable;
    };

    # Neither upstream timer sets Persistent. On a server that is irrelevant;
    # on a laptop it means the job is silently skipped rather than deferred --
    # the 04:00 scan never runs, because at 04:00 the lid is shut, and every
    # hourly signature update that falls inside a suspend is simply lost.
    #
    # Persistent makes systemd run the missed job on the next boot or resume, so
    # the evidence trail has an entry for every day the machine was used instead
    # of every day it happened to be awake at 4am.
    #
    # The delay keeps the catch-up run from starting the instant the lid opens,
    # which is exactly when the machine is least able to spare the cores.
    systemd.timers.clamdscan.timerConfig = {
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    systemd.timers.clamav-freshclam.timerConfig.Persistent = true;

    # Everything ClamAV runs is already collected into this slice upstream.
    # Capping it here rather than on the individual units means the nightly scan
    # cannot monopolise the machine when it catches up mid-morning, while still
    # leaving clamd responsive for on-access scanning if that is switched on.
    systemd.slices.system-clamav.sliceConfig = {
      CPUQuota = "50%";
      CPUWeight = 20;
      IOWeight = 20;
    };
  };
}
