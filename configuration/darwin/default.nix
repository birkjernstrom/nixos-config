{ config, pkgs, settings, ... }:

{
  imports = [
    ./modules
  ];

  config = {
    ids.uids.nixbld = 350;
    ids.gids.nixbld = 350;

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = [];

    # TODO: Remove this over time (2025-05-21)
    #   - Previously, some nix-darwin options applied to the user running
    #   `darwin-rebuild`. As part of a long‐term migration to make
    #   nix-darwin focus on system‐wide activation and support first‐class
    #   multi‐user setups, all system activation now runs as `root`, and
    #   these options instead apply to the `system.primaryUser` user.
    #       To continue using these options, set `system.primaryUser` to the name
    #   of the user you have been using to run `darwin-rebuild`. In the long
    #   run, this setting will be deprecated and removed after all the
    #   functionality it is relevant for has been adjusted to allow
    #   specifying the relevant user separately, moved under the
    #   `users.users.*` namespace, or migrated to Home Manager.
    system.primaryUser = "${settings.user}";

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;  # default shell on catalina
    # programs.fish.enable = true;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Setup user, packages, programs
    nix = {
      package = pkgs.nix;
      settings.trusted-users = [ "@admin" "${settings.user}" ];
      settings.experimental-features = "nix-command flakes";

      gc = {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
        options = "--delete-older-than 30d";
      };
    };

    system = {
      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      stateVersion = 4;

      # Set Git commit hash for darwin-version.
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
