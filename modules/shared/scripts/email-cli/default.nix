{ pkgs, lib, ... }:

let
  email-cli = pkgs.rustPlatform.buildRustPackage {
    pname = "email-cli";
    version = "0.1.0";

    src = ./.;

    cargoLock = {
      lockFile = ./Cargo.lock;
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    meta = with lib; {
      description = "Email management CLI for working through email backlog";
      homepage = "https://github.com/birkjernstrom/nixos-config";
      license = licenses.mit;
      maintainers = [ ];
    };
  };
in
{
  home.packages = [
    email-cli
    pkgs.himalaya  # Required backend
  ];
}
