{ pkgs ? import <nixpkgs> {} }:

import ./scripts/factory-install/env.nix {
  inherit pkgs;
}