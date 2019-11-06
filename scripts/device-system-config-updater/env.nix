{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-sf-device-system-config-updater = import ./release.nix { inherit nixpkgs; };
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-sf-device-system-config-updater-scripts-env";
  paths = [
    nixos-sf-device-system-config-updater
  ];
}
