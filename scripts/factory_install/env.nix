{ nixpkgs ? import <nixpkgs> {} }:

let
  common-install-scripts = nixpkgs.pkgs.callPackage ../common_install {};
  common-factory-install-scripts = nixpkgs.pkgs.callPackage ../factory_common_install {
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

