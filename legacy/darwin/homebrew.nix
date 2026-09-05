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

      # Communication Tools
      "discord"
      "loom"
      "zoom"
      "whatsapp"

      # Others
      "raycast"
      "obsidian"
      "spotify"
      "1password"

      # Terminal emulators
      "wezterm"
    ];
    brews = [
      "speakeasy-api/homebrew-tap/speakeasy"
    ];
    masApps = {
      # Mac App Store Installations
      # "1password" = 1333542190;
    };
  };
}
