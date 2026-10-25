{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.languages.c;

  clangdConfig = ''
    If:
      PathMatch: [.*\.c, .*\.h]
    CompileFlags:
      Compiler: gcc
      Add: [-xc, -std=c23, -Wall, -Wextra, -Wpedantic]
    ---
    Diagnostics:
      UnusedIncludes: Strict
      ClangTidy:
        Add: ["bugprone-*", "cert-*", "clang-analyzer-*", "performance-*", "portability-*"]
        Remove: [bugprone-easily-swappable-parameters, cert-err33-c]
  '';
in
{
  options.userSettings.programming.languages.c.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable C programming environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gcc
      gnumake
      cmake
      meson
      ninja
      pkg-config
      bear
      clang-tools
      man-pages
      man-pages-posix
    ] ++ optionals stdenv.hostPlatform.isLinux [
      gdb
      valgrind
    ];

    xdg.configFile."clangd/config.yaml" = mkIf pkgs.stdenv.hostPlatform.isLinux {
      text = clangdConfig;
    };

    home.file."Library/Preferences/clangd/config.yaml" = mkIf pkgs.stdenv.hostPlatform.isDarwin {
      text = clangdConfig;
    };
  };
}
