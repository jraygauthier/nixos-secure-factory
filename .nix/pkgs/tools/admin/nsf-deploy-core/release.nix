{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nsf-data-deploy-tools =
    (import ../nsf-data-deploy-tools/release.nix {
      inherit nixpkgs pkgs;
    }).default;
  nix-lib = pkgs.callPackage ./lib.nix {
    inherit nsf-data-deploy-tools; };
in

{
  inherit nix-lib;
}