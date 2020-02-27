{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-sf-data-deploy-tools = import ../nixos-sf-data-deploy-tools/release.nix {
    inherit nixpkgs; };
  release = nixpkgs.callPackage ./default.nix {
    inherit nixos-sf-data-deploy-tools; };
in

release