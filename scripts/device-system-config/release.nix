{ pkgs ? null } @ args:

let
  repoRootDir = ../..;
  pkgs = (import (
      repoRootDir + "/.nix/default.nix") {}
    ).ensurePkgs args;
in

with pkgs;

{
  default = callPackage ./. {};
}
