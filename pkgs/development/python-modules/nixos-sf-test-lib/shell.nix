{ pkgs ? import <nixpkgs> {} }:

import ./release.nix {
  inherit pkgs;
  fromNixShell = true;
}