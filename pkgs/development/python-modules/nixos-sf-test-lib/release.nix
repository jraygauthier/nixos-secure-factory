{ pkgs ? import <nixpkgs> {}
, fromNixShell ? false
}:

{
  release = pkgs.python3Packages.callPackage ./. {
    inherit fromNixShell;
  };
}
