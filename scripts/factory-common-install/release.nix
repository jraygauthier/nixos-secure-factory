{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  nixos-common-install-scripts = import ../common-install/release.nix { inherit nixpkgs; };
  nixos-device-system-config = import ../device-system-config/release.nix { inherit nixpkgs; };
  nixos-sf-device-system-config-updater = import ../device-system-config-updater/release.nix {
    inherit nixpkgs;
  };
  release = callPackage ./. {
    inherit nixos-common-install-scripts;
    inherit nixos-device-system-config;
    inherit nixos-sf-device-system-config-updater;
  };

in

(release // {
  envShellHook = writeScript "envShellHook.sh" ''
  '';
})
