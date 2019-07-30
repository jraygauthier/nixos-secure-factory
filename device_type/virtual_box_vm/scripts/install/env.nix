{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../../../../scripts/common_install {};
  device-common-install-scripts = nixpkgs.pkgs.callPackage ../../../../scripts/device_common_install {
    nixos-common-install-scripts = common-install-scripts;
  };
  device-install-scripts = nixpkgs.pkgs.callPackage ./. {
    nixos-device-common-install-scripts = device-common-install-scripts;

  };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-type-install-scripts-env";
  paths = [
    device-install-scripts
  ];
}