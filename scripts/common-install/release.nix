{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-common-scripts = import ../common/release.nix { inherit nixpkgs; };
in
(nixpkgs.pkgs.callPackage ./. { inherit nixos-common-scripts; })
