{ pkgs ? import <nixpkgs> {} }:

let
  nix-lib = pkgs.callPackage ./nix-lib {};
  python-lib = (import ./cli/release.nix { inherit pkgs; }).default;
  cli = python-lib;
in

{
  inherit nix-lib;
  inherit python-lib;
  inherit cli;
}
