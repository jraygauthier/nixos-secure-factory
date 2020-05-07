{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-common-install-scripts = (import
    ../common-install/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. {
    inherit nixos-common-install-scripts;
  };
}
