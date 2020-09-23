
{ lib
, writeShellScript
, runCommand
, coreutils
, makeWrapper
, jq
, nsf-deploy-core-nix-lib
, nsf-data-deploy-tools
, nsf-secrets-deploy-tools
}:

with nsf-deploy-core-nix-lib;

let
  dataDeployPerRuleTypeSchema = {
    "file" = {
      target = null;
      option = null;
      permission = null;
      type = null;
      source = null;
    };
    "mkdir" = {
      target  = null;
      option = null;
      permission = null;
      type = null;
    };
    "rmfile" = {
      target = null;
      option = null;
      type = null;
    };
  };

  isRuleOfDataDeployType = rule:
    dataDeployPerRuleTypeSchema ? "${rule.type}";

  secretsDeployPerRuleTypeSchema = {
    "pgp-file" = {
      type = null;
      target = null;
      source = null;
      option = null;
      permission = null;
      # run-as-user = null;
    };
    "pgp-gnupg-keyring" = {
      type = null;
      target = null;
      sources = null;
      otrust-sources = null;
      #target-user = null;
      #decrypt-gpg-homedir = null;
      #decrypt-as-user = null;
      #permission = null;
    };
  };

  perRuleTypeSchema = dataDeployPerRuleTypeSchema // secretsDeployPerRuleTypeSchema;

  assertValidRuleSchema =
    assertValidRuleSchemaImpl perRuleTypeSchema assertOptsWPropagatedBundleAttrs;

  assertDataDeployValidRuleType = assertValidRuleTypeImpl dataDeployPerRuleTypeSchema;
  assertSecretsDeployValidRuleType = assertValidRuleTypeImpl secretsDeployPerRuleTypeSchema;
  assertValidRuleType = assertValidRuleTypeImpl perRuleTypeSchema;

  assertValidRulesSchema =
    assertValidRulesSchemaImpl perRuleTypeSchema assertOptsWPropagatedBundleAttrs;

  resolveDataDeployRuleSources = x:
    if "file" == x.type then x // {
      source = resolveSourceFile x.source x.searchPaths x.option;
    }
    else
      assertDataDeployValidRuleType x;

  resolveSecretDeployRuleSources = x:
    if "pgp-file" == x.type
      then x // {
        source = resolveSourceFile x.source x.searchPaths x.option;
      }
    else if "pgp-gnupg-keyring" == x.type
      then x // {
        sources = resolveSourceFiles x.sources x.searchPaths x.option;
        otrust-sources = resolveSourceFiles x.otrust-sources x.searchPaths x.option;
      }
    else
      assertSecretsDeployValidRuleType x;

  resolveFlatRulesSources = unresolvedFlatRules:
    let
      resolve = x:
        if isRuleOfDataDeployType x
          # Delegate to data deploy resolver.
          then resolveDataDeployRuleSources x
        else
          resolveSecretDeployRuleSources x;
    in
      filterOutSourceResolverOptions (
        filterOutPropagatedBundleAttrsFromFlatRules(
          builtins.map resolve unresolvedFlatRules));

  mkResolvedBundleFromUnresolvedBundle = unresolvedBundle: {
    rules = resolveFlatRulesSources (assertValidRulesSchema unresolvedBundle.rules);
  };

  loadResolvedSecretsDeployBundle = bundleDir: bOpts:
    mkResolvedBundleFromUnresolvedBundle(
      flattenDataDeployBundleList (
        loadOptDataDeployUnresolvedBundleList
          bundleDir [bundleDir] bOpts
      )
    );

  filterOutOptionsWithDefaultValue = flatRules: let
      attrsFilter = k: v:
        if "replace-existing" == k && "always" == v
          then false
          else true;
    in
      lib.lists.forEach flatRules (x: x // {
        option = lib.attrsets.filterAttrs attrsFilter x.option;
      });

  filterOutEmptyAttrsetsNullOrDefaultValuesWithoutAddedMeaning = flatRules: let
      attrsFilter = k: v:
        if "option" == k && ({} == v || null == v)
          then false
        else if "permission" == k && ({} == v || null == v)
          then false
        else true;
    in
      lib.lists.forEach (
          filterOutOptionsWithDefaultValue flatRules) (x:
        lib.attrsets.filterAttrs attrsFilter x
      );

  mkRmFileRuleForNullSource = x:
    # When no source file, matching target should be removed.
    # TODO: Consider a flag for explicitly preventing this.
    assert null == x.source; {
      type = "rmfile";
      target = x.target;
      option = {};
    };

  mkBundledFileSource = source: target:
    ".${builtins.dirOf target}/${builtins.baseNameOf source}";

  mkBundledGnupgSource = sourceType: index: source: targetGpgDir:
    ".${targetGpgDir}/${sourceType}/${builtins.toString index}/${builtins.baseNameOf source}";

  mkBundledGnupgSources = sourceType: sources: targetGpgDir:
    lib.lists.imap0 (i: x: mkBundledGnupgSource sourceType i x targetGpgDir) sources;

  bundleDataDeployRule = x:
    if "file" == x.type then
      if null == x.source then
        mkRmFileRuleForNullSource x
      else x // {
        source = mkBundledFileSource x.source x.target;
      }
    else
      assertDataDeployValidRuleType x;

  bundleSecretsDeployRule = x:
    if "pgp-file" == x.type then
      if null == x.source then
        mkRmFileRuleForNullSource x
      else x // {
        source = mkBundledFileSource x.source x.target;
      }
    else if "pgp-gnupg-keyring" == x.type then
      x // {
        sources = mkBundledGnupgSources "keys" x.sources x.target;
        otrust-sources = mkBundledGnupgSources "otrust" x.otrust-sources x.target;
      }
    else
      assertSecretsDeployValidRuleType x;

  bundleFlatRules = flatRules:
    filterOutEmptyAttrsetsNullOrDefaultValuesWithoutAddedMeaning(
      lib.lists.forEach (
          filterOutSourceResolverOptions flatRules) (x:
        if isRuleOfDataDeployType x
          # Delegate to data deploy rule bundler.
          then bundleDataDeployRule x
        else
          bundleSecretsDeployRule x
      )
    );

  mkDerivationResolvedBundleFromResolvedBundle = resolvedBundle: {
    rules = bundleFlatRules resolvedBundle.rules;
  };

  listGatherSingleSourceFileCmds = outRootDir: source: target:
    let
      bundledRelFilePath = mkBundledFileSource source target;
      bundledRelDirPath = builtins.dirOf bundledRelFilePath;
    in [''
      mkdir -p "${outRootDir}/${bundledRelDirPath}"
      cp "${source}" "${outRootDir}/${bundledRelFilePath}"
    ''];

  listGatherGnupgSingleSourceFileCmds = outRootDir: sourceType: index: source: target:
    let
      bundledRelFilePath = mkBundledGnupgSource sourceType index source target;
      bundledRelDirPath = builtins.dirOf bundledRelFilePath;
    in [''
      mkdir -p "${outRootDir}/${bundledRelDirPath}"
      cp "${source}" "${outRootDir}/${bundledRelFilePath}"
    ''];

  listGatherGnupgMultiSourceFilesCmds = outRootDir: sourceType: sources: target:
    builtins.concatLists (
      lib.lists.imap0 (
        i: x: listGatherGnupgSingleSourceFileCmds outRootDir sourceType i x target)
        sources);

  listDataRuleGatherSourcesCmds = outRootDir: x:
    if "file" == x.type then
      lib.lists.optionals (null != x.source) (
        listGatherSingleSourceFileCmds outRootDir x.source x.target
      )
    else assert "mkdir" == x.type || "rmfile" == x.type; [];

  listSecretsRuleGatherSourcesCmds = outRootDir: x:
    if "pgp-file" == x.type then
      lib.lists.optionals (null != x.source) (
        listGatherSingleSourceFileCmds outRootDir x.source x.target
      )
    else if "pgp-gnupg-keyring" == x.type then (
        listGatherGnupgMultiSourceFilesCmds outRootDir "keys" x.sources x.target ++
        listGatherGnupgMultiSourceFilesCmds outRootDir "otrust" x.otrust-sources x.target
      )
    else assert false; [];

  printBundleGatherSourcesScript = resolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      mkdir -p "$bundled_rootfs"
    '' + (
      let
        outRootDir = "\${bundled_rootfs}";
      in
        lib.strings.concatStringsSep "" (lib.lists.flatten (
          lib.lists.forEach resolvedBundle.rules (x:
            if isRuleOfDataDeployType x
              # Delegate to data deploy rule bundler.
              then listDataRuleGatherSourcesCmds outRootDir x
            else
              listSecretsRuleGatherSourcesCmds outRootDir x
          )
        ))
    );

  writeBundleGatherSourcesScript = resolvedBundle:
    writeShellScript "nsf-secrets-deploy-install-script" (
      printBundleGatherSourcesScript resolvedBundle);

  listRuleDeployPermissionCmds = x:
    let
      permissions = if x ? permission then x.permission else {};

      owner = lib.strings.concatStrings (lib.lists.take 1 (
        lib.lists.optional (permissions ? user) permissions.user
        ++ lib.lists.optional (permissions ? uid) "${permissions.uid}"));
      ownerGroup = lib.strings.concatStrings (lib.lists.take 1 (
        lib.lists.optional (permissions ? group) permissions.group
        ++ lib.lists.optional (permissions ? gid) "${permissions.gid}"));
    in
      lib.lists.optional (null != permissions && permissions ? mode) ''
        nsf-file-chmod "''${out_prefix}${x.target}" "${permissions.mode}"
      ''
      ++ lib.lists.optional (null != permissions
          && (permissions ? user || permissions ? group
                || permissions ? uid || permissions ? gid)) ''
        nsf-file-chown "''${out_prefix}${x.target}" "${owner}" "${ownerGroup}"
      '';

  listDataRuleDeployCmds = bundleRootDir: x:
    let
      options = if x ? option then x.option else {};
      replaceExisting = if options ? replace-existing && null != options.replace-existing
        then options.replace-existing
        else "always";
    in (
      if "file" == x.type then
        # Should have already been replaced by a "rmfile" directive.
        assert null != x.source;
        # No other values supported yet.
        assert "always" == replaceExisting; [''
          nsf-file-deploy-w-inherited-permissions "${bundleRootDir}/${x.source}" "''${out_prefix}${x.target}"
        ''] ++ listRuleDeployPermissionCmds x
      else if "mkdir" == x.type then [''
          nsf-dir-mk-w-inherited-permissions "''${out_prefix}${x.target}"
        ''] ++ listRuleDeployPermissionCmds x
      else if "rmfile" == x.type then [''
          nsf-file-rm "''${out_prefix}${x.target}"
        '']
      else
        builtins.abort "Unknown rule type: ${x.type}!"
    );

  listSecretsRuleDeployCmds = bundleRootDir: x:
    let
      options = if x ? option then x.option else {};
      replaceExisting = if options ? replace-existing && null != options.replace-existing
        then options.replace-existing
        else "always";
    in (
      if "pgp-file" == x.type then
        # Should have already been replaced by a "rmfile" directive.
        assert null != x.source;
        # No other values supported yet.
        assert "always" == replaceExisting; [''
          nsf-pgp-file-deploy-w-inherited-permissions "${bundleRootDir}/${x.source}" "''${out_prefix}${x.target}"
        ''] ++ listRuleDeployPermissionCmds x
      else if "pgp-gnupg-keyring" == x.type then lib.lists.forEach x.sources (src: ''
          nsf-pgp-gnupg-keys-deploy "${bundleRootDir}/${src}" "''${out_prefix}${x.target}"
        '') ++ lib.lists.forEach x.otrust-sources (src: [''
          nsf-pgp-gnupg-otrust-deploy "${bundleRootDir}/${src}" "''${out_prefix}${x.target}"
        ''])
      else
        builtins.abort "Unknown rule type: ${x.type}!"
    );

  printBundleDeployScript = derivationResolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      out_prefix="''${2:-}"

    '' + (
    let
      bundleRootDir = "\${bundled_rootfs}";
    in
      lib.strings.concatStringsSep "" (lib.lists.flatten (
      lib.lists.forEach derivationResolvedBundle.rules (x:
        if isRuleOfDataDeployType x
          # Delegate to data deploy rule bundler.
          then listDataRuleDeployCmds bundleRootDir x
        else
          listSecretsRuleDeployCmds bundleRootDir x
      )))
    );

  writeBundleDeployScript = derivationResolvedBundle:
    writeShellScript "nsf-secrets-deploy-script" (
      printBundleDeployScript derivationResolvedBundle);


  listDataRuleDeployRuntimeDeps = [
    nsf-data-deploy-tools
  ];

  listSecretsRuleDeployRuntimeDeps = [
    nsf-secrets-deploy-tools
  ];

  mkSecretsDeployDerivationFromResolvedBundle = resolvedBundle:
    let
      rules = resolvedBundle.rules;
      derivationResolvedBundle = mkDerivationResolvedBundleFromResolvedBundle resolvedBundle;
      derivationResolvedBundleJson =
        writeToPrettyJson "deploy.json" derivationResolvedBundle;

      rulesInstallScriptDeps = [
        coreutils
      ];
      rulesDeployScriptDeps
        = listDataRuleDeployRuntimeDeps
       ++ listSecretsRuleDeployRuntimeDeps;

    in
      runCommand "nsf-secrets-deploy" {
          nativeBuildInputs = [
            makeWrapper
          ] ++ rulesInstallScriptDeps;
        } ''
        mkdir -p "$out"
        bundled_rootfs="$out/share/nsf-secrets-deploy/rootfs"
        mkdir -p "$bundled_rootfs"
        ${writeBundleGatherSourcesScript resolvedBundle} "$bundled_rootfs"
        cp ${derivationResolvedBundleJson} "$bundled_rootfs/deploy.json"

        mkdir -p "$out/bin"

        makeWrapper \
          "${writeBundleDeployScript derivationResolvedBundle}" \
          "$out/bin/nsf-secrets-deploy" \
          --prefix PATH : ${lib.makeBinPath rulesDeployScriptDeps} \
          --add-flags "$bundled_rootfs"
      '';

  mkSecretsDeployDerivation = dataDir: bOpts:
    let
      bundle = loadResolvedSecretsDeployBundle dataDir bOpts;
      drv = mkSecretsDeployDerivationFromResolvedBundle bundle;
    in
      drv;

  mkSecretsDeployPackage =
      { bundleDir
      , defaultImportsFn ? bundleDir: []
      }:
    mkSecretsDeployDerivation bundleDir {
      inherit defaultImportsFn;
    };
in

rec {
  impl = {
    inherit mkResolvedBundleFromUnresolvedBundle mkDerivationResolvedBundleFromResolvedBundle;
    inherit loadResolvedSecretsDeployBundle;
    inherit writeBundleGatherSourcesScript writeBundleDeployScript;
    inherit mkSecretsDeployDerivationFromResolvedBundle;
  };

  inherit filterOutPropagatedBundleAttrsFromFlatRules;
  inherit mkSecretsDeployDerivation mkSecretsDeployPackage;
}
