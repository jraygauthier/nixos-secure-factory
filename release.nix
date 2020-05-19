{ pkgs ? null } @ args:

let
  repoRootDir = ./.;
  dotNix = import (repoRootDir + "/.nix/release.nix") {};
  # pkgs = dotNix.ensurePkgs args;
in

# with pkgs;

{
  inherit (dotNix) overlay;
}
