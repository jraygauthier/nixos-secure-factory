{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-system-config = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-sf-device-system-config-env";
  paths = [
    nixos-device-system-config
  ];
}
