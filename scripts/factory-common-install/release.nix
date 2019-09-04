{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common-install {};
  device-system-update = nixpkgs.pkgs.callPackage ../device-system-config {};
in

(nixpkgs.pkgs.callPackage ./. {
  nixos-common-install-scripts = common-install-scripts;
  nixos-device-system-update = device-system-update;
})
