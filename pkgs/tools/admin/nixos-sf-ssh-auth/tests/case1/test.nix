{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  release =
    import ../../release.nix {
      inherit nixpkgs pkgs;
  };

  sshAuthLib = release.nix-lib;
in {
  inherit sshAuthLib;
  hello = "world";
}