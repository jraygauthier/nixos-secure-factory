{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-system-config = import ../device-system-config/release.nix { inherit nixpkgs; };
in

(nixpkgs.pkgs.callPackage ./. {
  inherit nixos-device-system-config;
})
