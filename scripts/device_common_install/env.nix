{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common_install {};
  common-device-install-scripts = nixpkgs.pkgs.callPackage ./default.nix {
    nixos-common-install-scripts = common-install-scripts;
  };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-common-install-scripts-env";
  paths = [
    common-install-scripts
    common-device-install-scripts
  ];
}
