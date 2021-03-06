{ pkgs ? null } @ args:

let
  repoRootDir = ../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
in

with pkgs;

{
  default = callPackage ./. { inherit nsf-common; };
}
