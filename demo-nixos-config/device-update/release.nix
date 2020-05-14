{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
}:

let
  pinnedSrcs = (
    import ../.nix/default.nix { inherit workspaceDir; }).pinned;

  nixpkgsChan = pinnedSrcs.nixpkgs.default;
  pkgs = import nixpkgsChan.src {};
  inherit (pkgs) nix-gitignore;
  sfChan = pinnedSrcs.nixos-secure-factory.default;

  deviceUpdate = import (sfChan.src + "/device-update/release.nix") {
    inherit deviceIdentifier deviceSystemConfigDir workspaceDir;
    inherit pkgs;
  };
in

deviceUpdate
