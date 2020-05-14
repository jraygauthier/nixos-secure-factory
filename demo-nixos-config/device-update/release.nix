{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
}:

let
  pinnedSrcs = (
    import ../.nix/default.nix { inherit workspaceDir; }).pinned;

  nixpkgs = pinnedSrcs.nixpkgs.default;
  pkgs = import nixpkgs.src {};
  inherit (pkgs) nix-gitignore;
  sfSrc = pinnedSrcs.nixos-secure-factory.default;

  deviceUpdate = import (sfSrc.src + "/device-update/release.nix") {
    inherit deviceIdentifier deviceSystemConfigDir workspaceDir;
    # TODO: Non standard interface. Change this.
    nixpkgs = pkgs;
  };
in

deviceUpdate
