{ nixpkgs ? null
, pkgs ? import (if null != nixpkgs then nixpkgs else <nixpkgs>) {}
}:

let
  nix-lib = pkgs.callPackage ./nix-lib {};
  python-lib = (import ./cli/release.nix { inherit nixpkgs pkgs; }).default;
  cli = python-lib;
in

{
  inherit nix-lib;
  inherit python-lib;
  inherit cli;
}
