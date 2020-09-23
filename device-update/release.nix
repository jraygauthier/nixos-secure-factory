{ deviceIdentifier
, deviceSystemConfigDir
, workspaceDir ? null
, pkgs ? import <nixpkgs> {}
}:

let
  nsf-device-system-config-updater = (import
    ../scripts/device-system-config-updater/release.nix {
      inherit pkgs;
    }).default;
in

pkgs.callPackage ./. {
  inherit deviceIdentifier deviceSystemConfigDir;
  inherit nsf-device-system-config-updater;
}
