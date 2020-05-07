{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  default = (import ./release.nix { inherit pkgs; }).default;
in

buildEnv {
  name = "${default.pname}-env";
  paths = [default];
}
