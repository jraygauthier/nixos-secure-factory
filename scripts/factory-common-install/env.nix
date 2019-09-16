{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-factory-common-install = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-factory-common-install-scripts-env";
  paths = [
    nixos-factory-common-install
  ];
}

