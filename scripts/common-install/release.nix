{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-common = (import
    ../common/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. { inherit nixos-sf-common; };
}
