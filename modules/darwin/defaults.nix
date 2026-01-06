{ config, pkgs, settings, ... }:

{
  config = {
    ids.uids.nixbld = 350;
    ids.gids.nixbld = 350;

    # List packages installed in system profile
    environment.systemPackages = [];

    # TODO: Remove this over time (2025-05-21)
    system.primaryUser = "${settings.user.name}";

    # Create /etc/zshrc that loads the nix-darwin environment
    programs.zsh.enable = true;

    # The platform the configuration will be used on
    nixpkgs.hostPlatform = "aarch64-darwin";

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Setup user, packages, programs
    nix = {
      package = pkgs.nix;
      settings.trusted-users = [ "@admin" "${settings.user.name}" ];
      settings.experimental-features = "nix-command flakes";

      gc = {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
        options = "--delete-older-than 30d";
      };
    };

    system = {
      # Used for backwards compatibility
      stateVersion = 4;

      # Set Git commit hash for darwin-version
      configurationRevision = config.rev or config.dirtyRev or null;

      defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          ApplePressAndHoldEnabled = false;

          KeyRepeat = 1;
          InitialKeyRepeat = 10;

          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.sound.beep.volume" = 0.0;
          "com.apple.sound.beep.feedback" = 0;
        };

        dock = {
          autohide = true;
          show-recents = false;
          launchanim = true;
          mouse-over-hilite-stack = true;
          orientation = "bottom";
          tilesize = 32;
          # Spaces, no re-arrange
          mru-spaces = false;
        };

        finder = {
          CreateDesktop = false;
        };

        trackpad = {
          Clicking = true;
          TrackpadThreeFingerDrag = true;
        };
      };

      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
    };
  };
}
