{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-system-config = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-system-config-scripts-env";
  paths = [
    nixos-device-system-config
  ];
}
