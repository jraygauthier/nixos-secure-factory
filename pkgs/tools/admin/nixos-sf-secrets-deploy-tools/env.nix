{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  release = import ./release.nix { inherit nixpkgs; };
  env = buildEnv {
    name = "${release.pname}-build-env";
    paths = [ release ];
  };
in

mkShell rec {
  name = "${release.pname}-env";
  buildInputs = [
    env
  ];
}

