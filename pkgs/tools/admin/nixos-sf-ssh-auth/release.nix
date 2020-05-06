{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nix-lib = pkgs.callPackage ./nix-lib {};
  cli = (import ./cli/release.nix { inherit nixpkgs pkgs; }).default;
in

{
  inherit nix-lib;
  inherit cli;
}
