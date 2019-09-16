{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-factory-common-install-scripts = import ../factory-common-install/release.nix { inherit nixpkgs; };
in

(nixpkgs.pkgs.callPackage ./. {
  inherit nixos-factory-common-install-scripts;
})
