
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  sshAuthUsers = callPackage ./nix-lib/ssh-auth-users.nix {};
  sshAuthGroups = callPackage ./nix-lib/ssh-auth-groups.nix {};
  sshAuthDir = callPackage ./nix-lib/ssh-auth-dir.nix {};
in rec {
  inherit sshAuthUsers sshAuthGroups sshAuthDir;
  inherit (sshAuthDir) mkAuthDirModule defaultDirCfg;
}
