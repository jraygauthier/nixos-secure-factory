
{ lib }:

rec {
  hasName = x:
    x ? "name";


  attrsetSameKeys = xAttrSet: yAttrSet:
    assert builtins.isAttrs xAttrSet;
    assert builtins.isAttrs yAttrSet;
      let
        xKs = lib.attrsets.attrNames xAttrSet;
        yKs = lib.attrsets.attrNames yAttrSet;
      in
    xKs == yKs;


  attrsetKeysDiff = xAttrSet: yAttrSet:
    assert builtins.isAttrs xAttrSet;
    assert builtins.isAttrs yAttrSet;
      let
        xKs = lib.attrsets.attrNames xAttrSet;
        yKs = lib.attrsets.attrNames yAttrSet;
        commonKs = lib.lists.intersectLists xKs yKs;
        mismatchingKs = lib.lists.unique (
             lib.lists.subtractLists commonKs xKs
          ++ lib.lists.subtractLists commonKs yKs
          );
      in
    mismatchingKs;


  printAttrsetKeysDiffStr = xAttrSet: yAttrSet:
    "${lib.strings.concatStringsSep "\n" (attrsetKeysDiff xAttrSet yAttrSet)}";


  onGenMissingAttr = ctxQualifier: ctxName: ctxPath: keyQualifierStr: attrsetQualifier: attrSetPath: ak: aset:
      let
        availUsersStr = lib.strings.concatStringsSep "\n" (lib.attrsets.attrNames aset);
      in
    assert lib.asserts.assertMsg false
      ( "Cannot expand \"${keyQualifierStr}\" '${ak}' from \"${ctxQualifier}\" '${ctxName}' defined in '${builtins.toString ctxPath}'.\n"
      + "This is because we cannot find '${ak}' in \"${attrsetQualifier}\" defined at '${builtins.toString attrSetPath}'.\n"
      + "A valid \"${keyQualifierStr}\" should be one of the following: ''\n${availUsersStr}\n''."
      );
    null;


  cherryPickFromAttrs = onMissingAttr: selectedKeys: attrset:
    lib.attrsets.genAttrs selectedKeys (ak:
        lib.attrsets.attrByPath [ ak ] (onMissingAttr ak attrset) attrset
      );


  printCompanionAttrSuggestionStr =
    attrSet: kPathInexistant: prefixStr: suffixStr:
      let
        parentPath = lib.lists.init kPathInexistant;
        parentASet = lib.attrsets.attrByPath parentPath {} attrSet;
        parentAvailSubKs = lib.attrsets.attrNames parentASet;
        suggestedPaths = map (x: parentPath ++ [x]) parentAvailSubKs;
        suggestedPathsStr = lib.strings.concatStringsSep "\n" (
          map (x: lib.strings.concatStringsSep "." x) suggestedPaths);
        suggestionStr =
          if [] == suggestedPaths then ""
            else "${prefixStr}${suggestedPathsStr}${suffixStr}";
      in
    suggestionStr;


  failOnMissingOrMismatchingTypeAttrOverridePred = attrSetId: oriAttrSet: kPath: oriV: overV:
    assert [] != kPath;
      let
        oriT = builtins.typeOf oriV;
        overT = builtins.typeOf overV;
        kPathStr = lib.strings.concatStringsSep "." kPath;
        missingKPathSuggestionStr =
          printCompanionAttrSuggestionStr
            oriAttrSet kPath " Did you mean: ''\n" "\n''";
      in
    assert lib.asserts.assertMsg (null != oriV) (
        "Found invalid `${attrSetId}` override attribute value of type '${overT}' at path '${kPathStr}'. "
      + "Nothing to override at this path.${missingKPathSuggestionStr}"
      );
    assert lib.asserts.assertMsg (overT == oriT) (
        "Found wrong `${attrSetId}` override attribute value type of '${overT}' at path '${kPathStr}'. "
      + "Expected a value of type '${oriT} at this path.'"
      );
    true;


  overrideAttrs = allowedPred: ori: overrides:
      let
        validOverrides = lib.lists.all lib.trivial.id (lib.attrsets.collect (x: ! builtins.isAttrs x) (
          lib.attrsets.mapAttrsRecursive (kPath: overV:
                let
                  oriV = lib.attrsets.attrByPath kPath null ori;
                in
              allowedPred ori kPath oriV overV
            )
            overrides));
      in
    assert validOverrides;
    lib.attrsets.recursiveUpdate ori overrides;


  mergePlainWExtra =
      plain:
      extra:
      {
        inherited,
        override,
        default ? {},
      } @ strategy:  # The strategy how to handle the extra attr set.
    assert inherited ? mergeLOf;
    assert inherited ? loadExtra;
    assert override ? mergeLOf;
    assert override ? loadExtra;
      let
        plainMerged = if ! builtins.isList plain then plain else
          assert default ? mergeLOf;
          default.mergeLOf plain;
        plainMergedWInherited = inherited.mergeLOf (
              lib.lists.optional (extra ? "inherited") extra.inherited
          ++  lib.lists.optional (extra ? "rawInherited") (
                inherited.loadExtra extra.rawInherited
              )
          ++  [ plainMerged ]
          );
        plainMergedWInheritedWOverride = override.mergeLOf (
            [ plainMergedWInherited ]
            ++  lib.lists.optional (extra ? "override") extra.override
            ++  lib.lists.optional (extra ? "rawOverride") (
                  override.loadExtra extra.rawOverride
                )
          );
      in
    plainMergedWInheritedWOverride;
}
