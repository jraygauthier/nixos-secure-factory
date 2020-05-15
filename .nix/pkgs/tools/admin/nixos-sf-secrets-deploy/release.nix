{ pkgs ? import <nixpkgs> {} }:

let
  nixos-sf-deploy-core-nix-lib =
    (import ../nixos-sf-deploy-core/release.nix {
      inherit pkgs;
    }).nix-lib;

  nixos-sf-data-deploy-tools =
    (import ../nixos-sf-data-deploy-tools/release.nix {
      inherit pkgs;
    }).default;

  nixos-sf-secrets-deploy-tools =
    (import ../nixos-sf-secrets-deploy-tools/release.nix {
      inherit pkgs;
    }).default;

  nix-lib =
    pkgs.callPackage ./lib.nix {
      inherit nixos-sf-deploy-core-nix-lib;
      inherit nixos-sf-data-deploy-tools;
      inherit nixos-sf-secrets-deploy-tools;
    };

  # TODO: Move under `nix-lib`.
  mkSecretsDeployPackage =
      { bundleDir
      , defaultImportsFn ? bundleDir: []
      }:
    nix-lib.mkSecretsDeployDerivation bundleDir {
      inherit defaultImportsFn;
    };
in

{
  inherit nix-lib;
  inherit mkSecretsDeployPackage;
}