{ config, lib, pkgs, nixpkgs-stable, settings, isDarwin, inputs, ... }:
let
  hostSettings = import ./settings.nix;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
    ./hardware.nix
    ../../modules/nixos/system.nix
    ../../modules/shared/system.nix
  ];

  # Apply system settings from settings.nix
  systemSettings = hostSettings.system;

  # Core Ultra X7 358H (Panther Lake, Xe3 graphics). The kernel already binds
  # this GPU to `xe` at runtime rather than `i915` (confirmed via `lsmod`:
  # `xe` has active users, `i915` has none), but common-cpu-intel's
  # nixos-hardware module defaults `hardware.intelgpu.driver` to "i915",
  # which controls which module gets preloaded in the initrd for early KMS.
  # Left unset, the wrong driver loads at that stage and gets displaced once
  # userspace takes over.
  hardware.intelgpu.driver = "xe";

  # The MIPI webcam (ov08x40 sensor) needs this: the in-tree kernel staging
  # driver alone enumerates the sensor but never brings up the ISP firmware
  # (journal: "IPU7 in secure mode" / "Failed to get runtime PM" on every
  # boot), so nothing ever produces a readable video stream. ipu75xa matches
  # this board's PCI ID (dmesg: "Device 0xb05d") - ipu7x is the Lunar Lake one.
  hardware.ipu7 = {
    enable = true;
    platform = "ipu75xa";
  };

  # The sensor is mounted upside down. Rotate in the relay rather than via the
  # sensor's flip controls, which would change the Bayer order the HAL's
  # sensor config expects (SGRBG10).
  services.v4l2-relayd.instances.ipu7.input.pipeline =
    lib.mkForce "icamerasrc ! videoflip video-direction=180";

  # The loopback device upstream creates gets v4l2loopback's default of 2
  # buffers, which GStreamer's v4l2sink can't cope with: it fails at once with
  # "buffer 1 was not queued, this indicate a driver bug", taking the relay
  # down on start and whenever a client (a Meet tab) disconnects - after which
  # every restart dies the same way until systemd's start limit gives up.
  # Tested: with 8 buffers the relay starts, serves frames and survives
  # clients leaving, every time.
  #
  # Also keep one device for the whole boot (reuse it, never delete it)
  # rather than upstream's add-on-start/delete-on-stop: the delete fails with
  # EBUSY while a browser holds the camera open, leaving a stale device
  # behind. And keep retrying restarts rather than giving up.
  systemd.services.v4l2-relayd-ipu7 =
    let
      ctl = "${config.boot.kernelPackages.v4l2loopback.bin}/bin/v4l2loopback-ctl";
      label = config.services.v4l2-relayd.instances.ipu7.cardLabel;
    in
    {
      preStart = lib.mkForce ''
        mkdir -p $(dirname $V4L2_DEVICE_FILE)
        for d in /sys/class/video4linux/video*; do
          if [ "$(cat $d/name 2>/dev/null)" = "${label}" ]; then
            echo /dev/$(basename $d) > $V4L2_DEVICE_FILE
            exit 0
          fi
        done
        ${ctl} add -x 1 -b 8 -n "${label}" > $V4L2_DEVICE_FILE
      '';
      postStop = lib.mkForce "";
      startLimitIntervalSec = 0;
      serviceConfig.RestartSec = 2;
    };

  # This board routes the sensor through an Intel CVS bridge
  # (ov08x40 -> Intel CVS -> IPU7 CSI2 0), which the camera HAL doesn't know
  # about: it takes the entity linked into CSI2 as the sensor (resolving the
  # sensor name to "ov08x40 S" and never finding it), and leaves the CVS pads
  # at their Y8 1x1 default so STREAMON fails with EPIPE on the format
  # mismatch. The patch looks the sensor up by name and sets the CVS formats.
  nixpkgs.overlays = [
    (final: prev: {
      ipu75xa-camera-hal = prev.ipu75xa-camera-hal.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./ipu7-cvs-bridge.patch ];
      });
    })
  ];

  # The stable kernel line has no SoundWire machine driver for this board's
  # ACPI configuration yet (dmesg: "No SoundWire machine driver found",
  # falls back to a generic HDA driver that only exposes the HDMI outputs -
  # no PCM for the internal speakers/headphones at all). Panther Lake is
  # new enough that this support is still landing upstream; latest tracks
  # mainline closely enough to carry it sooner than the default kernel would.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep the boot menu (and /boot, which is only 1G) in step with nix.gc.
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.hostName = "birk-xps"; # Define your hostname.
  boot.initrd.luks.devices."luks-e488d31f-e56b-4cc3-bd05-2717acd6728c".device = "/dev/disk/by-uuid/e488d31f-e56b-4cc3-bd05-2717acd6728c";
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Quickshell's bar reads these directly (Bar/modules/Bluetooth.qml,
  # Battery.qml) - Noctalia used to backfill all three via
  # `programs.noctalia.recommendedServices`, which stood down with it.
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";
  services.timesyncd.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Enable the X11 window system + GNOME Desktop Environment.
  services.xserver.enable = true;
  services.xserver.xkb = {
    # A US layout with å/ö/ä on AltGr+[ ; ' -- see modules/nixos/hyprland/home.nix.
    layout = "se";
    variant = "us";
  };

  # Reuse the same layout on the virtual consoles.
  console.useXkbConfig = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # GDM otherwise defaults to GNOME on a fresh install until a session choice
  # is remembered in /var/lib/AccountsService.
  services.displayManager.defaultSession = "hyprland";
  programs.dconf.enable = true;
  services.keyd.enable = true;
  services.keyd.keyboards.default = {
    ids = ["*"];
    settings = {
      main = {
        capslock = "leftcontrol";
      };
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # The haptic Synaptics touchpad (06CB:D01D) tracks fine from a cold boot
  # but ignores presses until it has been power-cycled once - a suspend
  # (closing the lid) fixes it every time. Do the same once at boot:
  # unbinding i2c_hid_acpi powers the device down, rebinding powers it back
  # up and re-runs hid-multitouch's setup, as a resume does.
  systemd.services.touchpad-reinit =
    let
      dev = "i2c-VEN_06CB:00";
      drv = "/sys/bus/i2c/drivers/i2c_hid_acpi";
    in
    {
      description = "Power-cycle the haptic touchpad so clicks register";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        for _ in $(seq 60); do
          [ -e ${drv}/${dev} ] && break
          sleep 0.5
        done
        [ -e ${drv}/${dev} ] || exit 0
        echo ${dev} > ${drv}/unbind
        sleep 2
        echo ${dev} > ${drv}/bind
      '';
    };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.birk = {
    isNormalUser = true;
    description = "Birk Jernstrom";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [
      firefox
      _1password-gui
    ];
  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    vim
    wget

    # Only in case GNOME is enabled
    dconf
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  };

  # Power management / sleep
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };



  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
