{ pkgs ? import <nixpkgs> {} }:

let
  repo = (import ../../local-or-pinned-src/nsf-shell-complete.nix {}).src;
  release = (import "${repo}/release.nix" {
      inherit pkgs;
    });
in

release