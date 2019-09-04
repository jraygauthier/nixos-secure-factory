{ nixpkgs ? import <nixpkgs> {} }:

let
  install-scripts = nixpkgs.pkgs.callPackage ./default.nix {};
in

nixpkgs.pkgs.buildEnv {
  name = "nixos-common-install-scripts-env";
  paths = [
    install-scripts
  ];
}
