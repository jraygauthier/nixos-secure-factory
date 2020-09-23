{ pkgs ? null } @ args:

let
  repoRootDir = ../../../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
in

with pkgs;

rec {
  default = callPackage ./. {
    inherit nsf-device-common-install;
  };

  env = buildEnv {
    name = "${default.pname}-env";
    paths = [
      default
    ];
  };
}