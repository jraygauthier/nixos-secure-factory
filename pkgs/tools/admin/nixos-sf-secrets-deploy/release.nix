{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nixos-sf-deploy-core-nix-lib =
    (import ../nixos-sf-deploy-core/release.nix {
      inherit nixpkgs pkgs;
    }).nix-lib;

  nixos-sf-data-deploy-tools =
    (import ../nixos-sf-data-deploy-tools/release.nix {
      inherit nixpkgs pkgs;
    }).release;

  nixos-sf-secrets-deploy-tools =
    (import ../nixos-sf-secrets-deploy-tools/release.nix {
      inherit nixpkgs pkgs;
    }).release;

  nix-lib =
    pkgs.callPackage ./lib.nix {
      inherit nixos-sf-deploy-core-nix-lib;
      inherit nixos-sf-data-deploy-tools;
      inherit nixos-sf-secrets-deploy-tools;
    };

  deployBundleDir =
      { dataBundleDir
      , defaultImportsFn ? dataBundleDir: []
      }:
    nix-lib.mkSecretsDeployDerivation dataBundleDir {
      inherit defaultImportsFn;
    };
in

{
  inherit nix-lib;
  inherit deployBundleDir;
}
