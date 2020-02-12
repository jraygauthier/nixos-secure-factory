{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
}:

let
  nixpkgsSrc = libSrc.getPinnedSrc "nixpkgs";
  nixpkgs = import nixpkgsSrc.src {};
  inherit (nixpkgs) nix-gitignore;

  libSrc = import ../lib/src.nix { inherit workspaceDir; };
  sfSrc = libSrc.getPinnedSrc "nixos-secure-factory";

  deviceUpdate = import (sfSrc.src + "/device-update/release.nix") {
    inherit deviceIdentifier deviceSystemConfigDir workspaceDir;
    inherit nixpkgs;
  };
in

deviceUpdate
