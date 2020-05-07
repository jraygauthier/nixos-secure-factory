{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-common-scripts = (import
    ../common/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. { inherit nixos-common-scripts; };
}
