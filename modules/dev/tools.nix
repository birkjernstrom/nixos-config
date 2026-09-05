# Development tools that are not tied to one language.
{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = [ pkgs.lazydocker ];
  };
}
