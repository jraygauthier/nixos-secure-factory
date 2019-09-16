{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-type-install-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-type-install-scripts-env";
  paths = [
    nixos-device-type-install-scripts
  ];
}