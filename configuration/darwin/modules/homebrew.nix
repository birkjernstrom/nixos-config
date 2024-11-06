{ config, pkgs, settings, ... }:

{
  homebrew = {
    enable = true;
    casks = [
      # Development Tools
      "homebrew/cask/docker"
      "ngrok"
      "postico"
      "visual-studio-code"
      "utm"  # QEMU VM

      # Communication Tools
      "discord"
      "loom"
      "slack"
      "zoom"
      "whatsapp"

      # Others
      "raycast"
      "obsidian"
      "spotify"
      "1password"

      # Browsers
      "google-chrome"

      # Terminal emulators
      "wezterm"
    ];
    masApps = {
      # Mac App Store Installations
      # "1password" = 1333542190;
    };
  };
}
