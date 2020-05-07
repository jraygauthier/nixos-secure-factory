{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-device-system-config = (import
    ../device-system-config/release.nix {
      inherit pkgs;
    }).default;
in

{
  default = callPackage ./. {
      inherit nixos-device-system-config;
    };
}
