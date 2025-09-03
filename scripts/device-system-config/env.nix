{ pkgs ? null } @ args:

let
  repoRootDir = ../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
in

with pkgs;

let
  default = (import ./release.nix {inherit pkgs;}).default;
in

buildEnv {
  name = "${default.pname}-env";
  paths = [default];
}
