{ pkgs ? import <nixpkgs> {} }:

let
  repo = (import ../../../default.nix { inherit pkgs; }
    ).srcs.localOrPinned.nsf-shell-complete.default.src;
  release = (import "${repo}/release.nix" {
      inherit pkgs;
    });
in

release