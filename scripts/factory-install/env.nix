{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common-install {};
  common-factory-install-scripts = nixpkgs.pkgs.callPackage ../factory-common-install {
    nixos-common-install-scripts = common-install-scripts;
  };
  factory-install-scripts = nixpkgs.pkgs.callPackage ./default.nix {
    nixos-factory-common-install-scripts = common-factory-install-scripts;
  };

in

nixpkgs.pkgs.buildEnv {
  name = "nixos-factory-install-scripts-env";
  paths = [
    # common-install-scripts
    factory-install-scripts
  ];
}

