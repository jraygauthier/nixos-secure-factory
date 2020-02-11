{ device_identifier
, device_system_config_dir
, workspaceDir ? null
# TODO: No longer needed. Deprecated. Remove at some point.
, device_system_config_src_dir ? null
}:

let
  nixpkgsSrc = libSrc.getPinnedSrc "nixpkgs";
  nixpkgs = import nixpkgsSrc.src {};
  inherit (nixpkgs) nix-gitignore;

  libSrc = import ../lib/src.nix { inherit workspaceDir; };
  sfSrc = libSrc.getPinnedSrc "nixos-secure-factory";

  deviceUpdate = import (sfSrc.src + "/device-update/release.nix") {
    inherit device_identifier device_system_config_dir workspaceDir;
    inherit nixpkgs;
  };
in

deviceUpdate
