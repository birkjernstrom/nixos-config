# Docker.
#
# macOS has no Docker daemon of its own, so colima provides one and the CLI
# comes from homebrew. Linux runs the real thing as a system service, with the
# user in the docker group.
{
  flake.modules.darwin.gui-apps = {
    homebrew.brews = [ "docker" "colima" "lazydocker" ];
  };

  flake.modules.nixos.desktop = {
    virtualisation.docker.enable = true;
    users.users.birk.extraGroups = [ "docker" ];
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = [ pkgs.lazydocker ];
  };
}
