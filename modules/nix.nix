# Nix daemon settings and store housekeeping.
{
  flake.modules.nixos.base = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Collect garbage weekly, keeping the last week of generations. The current
    # generation is always kept regardless of age.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
