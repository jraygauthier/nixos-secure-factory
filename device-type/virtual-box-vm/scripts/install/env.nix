{ pkgs ? import <nixpkgs> {} }:

(import ./release.nix { inherit pkgs; }).env
