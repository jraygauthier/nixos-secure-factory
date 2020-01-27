{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  nixos-factory-common-install = import ../factory-common-install/release.nix { inherit nixpkgs; };

  release = callPackage ./. {
    inherit nixos-factory-common-install;
  };


in

(release // {
  envShellHook = writeScript "envShellHook.sh" ''
    source "${nixos-factory-common-install.envShellHook}"
  '';
})