{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  release =
    import ../release.nix {
      inherit nixpkgs pkgs;
  };

  secretsDeployLib = release.nix-lib;
in

with secretsDeployLib; secretsDeployLib // {

}