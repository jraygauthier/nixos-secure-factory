{ lib }:
# TODO: Remove and use new framework.
{
  getUserKeyFileFromPerUserAuthKeys = username: inAttrSet: let
      userAuthKeyAttrSet = inAttrSet."${username}" or {};
      userAuthKeyAttrList = lib.attrValues userAuthKeyAttrSet;
      validatedSet = set:
        assert lib.asserts.assertMsg (set != {}) "Set should be non empty";
        assert builtins.all (x: x) (map (k: lib.asserts.assertOneOf "k" k ["public_key_file"]) (lib.attrNames set));
        set;
      attrSetFilter = v: (validatedSet v) ? "public_key_file";
      out = map (v: ../device-ssh/authorized/. + "/${v.public_key_file}") (
        builtins.filter attrSetFilter userAuthKeyAttrList);
    in out;
}
