{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common_install {};
in

(nixpkgs.pkgs.callPackage ./. {
  nixos-common-install-scripts = common-install-scripts;
})
