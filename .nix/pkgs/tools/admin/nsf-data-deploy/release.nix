{ pkgs ? import <nixpkgs> {}}:

let
  nsf-deploy-core-nix-lib =
    (import ../nsf-deploy-core/release.nix {
      inherit pkgs;
    }).nix-lib;

  nsf-data-deploy-tools =
    (import ../nsf-data-deploy-tools/release.nix {
      inherit pkgs;
    }).default;

  nix-lib =
    pkgs.callPackage ./lib.nix {
      inherit nsf-deploy-core-nix-lib;
      inherit nsf-data-deploy-tools;
    };
in

{
  inherit nix-lib;
  # TODO: Remove at some point. Kept for backward compat.
  inherit (nix-lib) mkDataDeployPackage;
}
