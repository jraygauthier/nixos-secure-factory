{ pkgs ? import <nixpkgs> {} }:

let
  repo = (import ../../../../.nix/default.nix { inherit pkgs; }
    ).srcs.localOrPinned.nixos-sf-ssh-auth.default.src;
  release = (import "${repo}/release.nix" {
      inherit pkgs;
    });
in

release