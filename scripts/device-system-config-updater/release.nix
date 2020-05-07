{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-device-system-config = (import
    ../device-system-config/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. {
      inherit nixos-sf-device-system-config;
    };
}
