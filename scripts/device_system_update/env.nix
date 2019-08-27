{ nixpkgs ? import <nixpkgs> {} }:

let
  install-scripts = nixpkgs.pkgs.callPackage ./default.nix {};
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-device-system-update-scripts-env";
  paths = [
  ];
}
