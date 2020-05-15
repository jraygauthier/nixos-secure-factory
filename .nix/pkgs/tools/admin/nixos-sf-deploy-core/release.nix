{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nixos-sf-data-deploy-tools =
    (import ../nixos-sf-data-deploy-tools/release.nix {
      inherit nixpkgs pkgs;
    }).default;
  nix-lib = pkgs.callPackage ./lib.nix {
    inherit nixos-sf-data-deploy-tools; };
in

{
  inherit nix-lib;
}