{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  release = import ./release.nix { inherit nixpkgs; };
in

mkShell rec {
  name = "${release.pname}-shell";
  inputsFrom = [
    release
  ];
}

