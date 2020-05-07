{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-common-install-scripts = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-sf-common-install-env";
  paths = [
    nixos-common-install-scripts
  ];
}
