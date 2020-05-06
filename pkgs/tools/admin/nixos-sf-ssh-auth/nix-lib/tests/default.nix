{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  inherit (pkgs)
    symlinkJoin
    writeTextDir
    writeText;

  testTools = pkgs.callPackage ../test-tools.nix {};
  sshAuthLib = pkgs.callPackage ../. {};

  commonLocalDeps = { inherit testTools sshAuthLib; };

  test-core = pkgs.callPackage ./test-core.nix commonLocalDeps;
  test-auth-dir-device-user = pkgs.callPackage ./test-auth-dir-device-user.nix commonLocalDeps;
  test-auth-dir = pkgs.callPackage ./test-auth-dir.nix commonLocalDeps;
  test-users = pkgs.callPackage ./test-users.nix commonLocalDeps;
  test-groups = pkgs.callPackage ./test-groups.nix commonLocalDeps;
  test-auth = pkgs.callPackage ./test-auth.nix commonLocalDeps;
  test-auth-dir-w-extra = pkgs.callPackage ./test-auth-dir-w-extra.nix commonLocalDeps;
  test-auth-dir-device-user-w-extra = pkgs.callPackage ./test-auth-dir-device-user-w-extra.nix commonLocalDeps;
in

with testTools;
with sshAuthLib;

rec {
  # TODO: Detect duplicate test names / make sure to make names unique by
  # including context attrs keys.
  tests = test-core // test-auth-dir-device-user // test-auth-dir // test-users // test-groups
    // test-auth // test-auth-dir-w-extra // test-auth-dir-device-user-w-extra;

  runTestsAll =
    assert testTools.assertAllNixTestsOk tests;
    "";
}
