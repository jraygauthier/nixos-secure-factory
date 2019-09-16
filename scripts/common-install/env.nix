{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-common-install-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-common-install-scripts-env";
  paths = [
    nixos-common-install-scripts
  ];
}
