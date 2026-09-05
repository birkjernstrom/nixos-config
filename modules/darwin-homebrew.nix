# The homebrew casks and brews that no feature module owns.
#
# Apps that do have a module - slack, obsidian, todoist, the browsers, ghostty,
# docker - are declared in modules/apps/ instead, next to their Linux
# equivalents, so one file describes the app on both platforms.
{
  flake.modules.darwin.base = {
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
  };
}
