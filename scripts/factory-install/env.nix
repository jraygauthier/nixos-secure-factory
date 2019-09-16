{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-factory-install-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-factory-install-scripts-env";
  paths = [
    nixos-factory-install-scripts
  ];
}

