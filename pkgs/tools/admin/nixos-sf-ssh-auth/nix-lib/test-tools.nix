
{ lib
, stdenv
, yq
, jq
} @ args:

let
  callPackage = lib.callPackageWith args;
in

rec {
  toPrettyJsonStr = nixValue:
      let
        jsonStr = builtins.toJSON nixValue;
        jsonFile = builtins.toFile "ugly.json" jsonStr;
        prettyJsonFile = stdenv.mkDerivation rec {
          name = "pretty.json";
          phases = [ "installPhase" ];

          nativeBuildInputs = [ jq ];

          installPhase = ''
            cat "${jsonFile}" | jq '.' > "$out"
          '';
        };

        prettyJsonStr = builtins.readFile prettyJsonFile;

      in
    prettyJsonStr;


  toPrettyYamlStr = nixValue:
      let
        # TODO: Improve the opaque "cannot convert a function to JSON" error
        # by replacing functions by strings in a similar fashion as nix repl.
        jsonStr = builtins.toJSON nixValue;
        jsonFile = builtins.toFile "ugly.json" jsonStr;
        prettyJsonFile = stdenv.mkDerivation rec {
          name = "pretty.yaml";
          phases = [ "installPhase" ];

          nativeBuildInputs = [ yq ];

          installPhase = ''
            cat "${jsonFile}" | yq -y '.' > "$out"
          '';
        };

        prettyJsonStr = builtins.readFile prettyJsonFile;

      in
    prettyJsonStr;


  testResultsToPerTestAttrs = results:
    builtins.listToAttrs (
      builtins.map (r: {
          inherit (r) name; value = { inherit (r) expected result; };
        })
        results);


  # TODO: Variant that takes either a list of attr set, or a list so that
  # ordering of tests is taken under consideration.
  assertAllNixTestsOk = testsAttrSet:
      let
        printSuccessStr = t: if (t.expr == t.expected) then "ok" else "fail";
        testsAttrSetWLogTrace = lib.attrsets.mapAttrs (k: v:
          v // {
            expr = builtins.trace "## ${k} ##" v.expr;
          }) testsAttrSet;
        testAll = lib.debug.runTests testsAttrSetWLogTrace;
        prettyResultsStr = toPrettyYamlStr (testResultsToPerTestAttrs testAll);
      in
    lib.asserts.assertMsg (0 == lib.lists.length testAll)
      "Failing tests (as yaml):\n${prettyResultsStr}";


  checkFails = test:
      let
        eval = if test ? "expected"
          then (test.expected == test.expr)
          else test.expr;
      in
    test // {
      expr = (builtins.tryEval (builtins.deepSeq test.expr eval)).success;
      expected = false;
    };
}
