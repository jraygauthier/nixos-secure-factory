{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-common-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-common-scripts-env";
  paths = [
    nixos-common-scripts
  ];
}
