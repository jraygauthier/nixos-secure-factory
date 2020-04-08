{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nixos-sf-data-deploy-tools =
    (import ../nixos-sf-data-deploy-tools/release.nix {
      inherit nixpkgs pkgs;
    }).release;
  nix-lib = pkgs.callPackage ./lib.nix {
    inherit nixos-sf-data-deploy-tools; };
in

{
  inherit nix-lib;
}