{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-device-common-install-scripts = import ../../../../scripts/device-common-install {
    inherit nixpkgs;
  };
in

(nixpkgs.pkgs.callPackage ./. {
  inherit nixos-device-common-install-scripts;
})
