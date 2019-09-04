{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common-install {};
  device-system-update = nixpkgs.pkgs.callPackage ../device-system-config {};
  install-scripts = nixpkgs.pkgs.callPackage ./default.nix {
    nixos-common-install-scripts = common-install-scripts;
    nixos-device-system-update = device-system-update;
  };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-factory-common-install-scripts-env";
  paths = [
    common-install-scripts
    nixos-device-system-update
    install-scripts
  ];
}

