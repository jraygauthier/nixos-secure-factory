{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
, pkgs ? import <nixpkgs> {}
}:

let
  nixos-sf-device-system-config-updater = (import
    ../scripts/device-system-config-updater/release.nix {
      inherit pkgs;
    }).default;
in

pkgs.callPackage ./. {
  inherit deviceIdentifier deviceSystemConfigDir;
  inherit nixos-sf-device-system-config-updater;
}
