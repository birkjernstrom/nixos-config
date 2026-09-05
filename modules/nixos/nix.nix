# Nix store housekeeping (system-level)
{ ... }:

{
  # Collect garbage weekly, keeping the last week of generations. The current
  # generation is always kept regardless of age.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
