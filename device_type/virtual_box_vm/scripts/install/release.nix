{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../../../../scripts/common-install {};
  device-common-install-scripts = nixpkgs.pkgs.callPackage ../../../../scripts/device-common-install {
    nixos-common-install-scripts = common-install-scripts;
  };
in

(nixpkgs.pkgs.callPackage ./. {
  nixos-device-common-install-scripts = common-install-scripts;
})
