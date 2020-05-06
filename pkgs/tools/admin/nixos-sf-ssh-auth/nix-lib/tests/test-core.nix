{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;
with coreModule;

let
  overrideAttrsExample = overrideAttrs (failOnMissingOrMismatchingTypeAttrOverridePred "myAttrSetId");
in

{
  testOverrideAuthDirCfgEmptyOverride = let ori = {a.b.c = 2; b = 3;}; in
    {
      expr = overrideAttrsExample ori {};
      expected = ori;
    };

  testOverrideAuthDirCfgMultiple =
    {
      expr = overrideAttrsExample {a.b.c = 2; b = 3; c.b = [ 4 ];} {a.b.c = 5; c.b = [ 6 ]; };
      expected = {a.b.c = 5; b = 3; c.b = [ 6 ];};
    };

  testOverrideAuthDirCfgInvalidAttrError = checkFails
    {
      expr = overrideAttrsExample {a.b.c = 2;} {a.c = "3";};
      expected = {};
    };

  testOverrideAuthDirCfgStringOverAttrSetWrongAttrValueTypeError = checkFails
    {
      expr = overrideAttrsExample {a.b.c = 2;} {a.b = "3";};
      expected = {};
    };

  testOverrideAuthDirCfgIntOverListWrongAttrValueTypeError = checkFails
    {
      expr = overrideAttrsExample {c.b = [ 4 ];} {c.b = 5;};
      expected = {};
    };
}
