{ pkgs ? null
# , workspaceDir ? builtins.toString ../.
} @ args:

let
  repoRootDir = ./.;
  dotNix = import (repoRootDir + "/.nix/release.nix") {
    inherit pkgs;
    # TODO: Check if this is required for provided overlays
    # to find local sources.
    # inherit workspaceDir;
  };
  # pkgs = dotNix.ensurePkgs args;
in

# with pkgs;

{
  inherit (dotNix) overlay;
}
