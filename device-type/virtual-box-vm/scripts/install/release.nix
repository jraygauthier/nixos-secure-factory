{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-device-common-install = import
    ../../../../scripts/device-common-install/release.nix {
      inherit pkgs;
    };
in

(callPackage ./. {
  inherit nixos-sf-device-common-install;
})
