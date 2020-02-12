{ device_identifier ? null # TODO: Deprecated. Remove.
, deviceIdentifier ? device_identifier # TODO: Make mandatory once above removed.
, device_system_config_dir ? null # TODO: Deprecated. Remove.
, deviceSystemConfigDir ? device_system_config_dir # TODO: Make mandatory once above removed.
, workspaceDir ? null
# TODO: No longer needed. Deprecated. Remove at some point.
, device_system_config_src_dir ? null
}:

# TODO: Remove once deprecation expired.
assert null != deviceIdentifier;
assert null != deviceSystemConfigDir;

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
