{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-common-install-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-common-install-scripts-env";
  paths = [
    nixos-device-common-install-scripts
  ];
}
