{ pkgs ? import <nixpkgs> {} }:

let
  repo = (import ../../../local-or-pinned-src/nixos-sf-ssh-auth.nix {}).src;
  release = (import "${repo}/release.nix" {
      inherit pkgs;
    });
in

release