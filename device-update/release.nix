{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
, nixpkgs ? import <nixpkgs> {}
}:

let
  nixos-sf-device-system-config-updater = (import
    ../scripts/device-system-config-updater/release.nix {
      pkgs = nixpkgs;
    }).default;
in

nixpkgs.callPackage ./. {
  inherit deviceIdentifier deviceSystemConfigDir;
  inherit nixos-sf-device-system-config-updater;
}
