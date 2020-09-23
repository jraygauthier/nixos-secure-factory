{ pkgs ? import <nixpkgs> {}}:

let
  release =
    import ../release.nix {
      inherit pkgs;
  };

  secretsDeployLib = release.nix-lib;
in

with secretsDeployLib; secretsDeployLib // {

}