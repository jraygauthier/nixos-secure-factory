{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-device-common-install = (import
    ../../../../scripts/device-common-install/release.nix {
      inherit pkgs;
    }).default;
in

rec {
  default = callPackage ./. {
    inherit nixos-sf-device-common-install;
  };

  env = buildEnv {
    name = "${default.pname}-env";
    paths = [
      default
    ];
  };
}