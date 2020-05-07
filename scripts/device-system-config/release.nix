{ pkgs ? import <nixpkgs> {} }:

with pkgs;

{
  default = callPackage ./. {};
}
