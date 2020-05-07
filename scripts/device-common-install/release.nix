{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-common-install = (import
    ../common-install/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. {
    inherit nixos-sf-common-install;
  };
}
