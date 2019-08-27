{ nixpkgs ? import <nixpkgs> {} }:

(nixpkgs.pkgs.callPackage ./. {})
