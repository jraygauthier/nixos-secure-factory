{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  nix-lib =
    pkgs.callPackage ./lib.nix {
    };
in

{
  inherit nix-lib;
}
