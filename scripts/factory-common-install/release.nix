{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  nixos-common-install-scripts = import ../common-install/release.nix { inherit nixpkgs; };
  nixos-device-system-config = import ../device-system-config/release.nix { inherit nixpkgs; };
  release = callPackage ./. {
    inherit nixos-common-install-scripts;
    inherit nixos-device-system-config;
  };

in

(release // {
  envShellHook = writeScript "envShellHook.sh" ''
  '';
})
