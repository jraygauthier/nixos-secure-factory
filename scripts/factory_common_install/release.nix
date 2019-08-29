{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common_install {};
  device-system-update = nixpkgs.pkgs.callPackage ../device_system_config {};
in

(nixpkgs.pkgs.callPackage ./. {
  nixos-common-install-scripts = common-install-scripts;
  nixos-device-system-update = device-system-update;
})
