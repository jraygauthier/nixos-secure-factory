
{ lib
, writeShellScript
, runCommand
, coreutils
, makeWrapper
, jq
}:

let
  toAsbPath = fn:
    assert builtins.isPath fn || builtins.isString fn;
    if builtins.isPath fn then fn else
      if lib.strings.hasPrefix "/" fn then (/. + fn)
        else abort "Expected an absolute path but instead received: '${fn}'.";

  resolveAsbFilepath = bundleDir: fn:
    assert builtins.isPath bundleDir;
    assert builtins.isPath fn || builtins.isString fn;
    if builtins.isPath fn then fn else
      if lib.strings.hasPrefix "/" fn then (/. + fn)
        else (bundleDir + "/${fn}");

  flattenRules = loadedRules:
    let
      rulesFillMissing = x: x // {
        permission = if x ? permission then x.permission else null;
        option = if x ? option && x.option != null then x.option else {};
      };
      rulesListFillMissing = xs:
        builtins.map rulesFillMissing xs;
      rulesAttr2List = x:
        lib.attrsets.mapAttrsToList (k: v:
          rulesFillMissing (v // {
            target = k;
          })
        ) x;

    in
      # Support both attrset rules and list rules.
      if lib.isList loadedRules
        then rulesListFillMissing loadedRules
        else rulesAttr2List loadedRules;

  getBundleDefaultImports = bundleDir:
      opts@{ defaultImportsFn }:
    # defaultImportsFn bundleDir;
    lib.lists.forEach (defaultImportsFn bundleDir)(x:
    if builtins.isAttrs x
      then assert x ? path
            || builtins.trace "Missing 'path' attribute on default imports for '${toString bundleDir}'!";
        x // {
          path = toAsbPath x.path;
          default-import = true;
        }
      else {
        path = toAsbPath x;
        allow-inexistent = true;
        default-import = true;
    });


  getBundleImports = bundleDir: bundle: opts:
    # TODO: Consider how to allow having an explicit import listing
    #       which allows to explicitly defer to default imports.
    #
    #       IDEA: Could be by specifying a attrset instead of a
    #             path / string which would allow special options.
    #             `{ path = null, default-imports = true}`.
    #
    #             Could be by using some template expension scheme
    #             within the string: `"${default-imports}"`.
    #
    #             Could be by using `null` as a sentinel value for
    #             this purpose.
    #
    #       For the moment, when an explicit import list is
    #       provided, it will be the reponsability of the importer
    #       to import or not the import what would have been default
    #       imported.
    if bundle ? imports
      then bundle.imports
      else getBundleDefaultImports bundleDir opts;

  mkDefaultBundle = bundleDir: opts: {
    bundleDir = toAsbPath bundleDir;
    imports = getBundleDefaultImports bundleDir opts;
  };

  loadDeployFileAt = absFn: opts:
    let
      fnCwd = builtins.dirOf absFn;
      rawBundle = builtins.fromJSON (builtins.readFile absFn);
    in
      rawBundle // {
        bundleDir = fnCwd;
        imports = getBundleImports fnCwd rawBundle opts;
      };

  resolveDataDeployFilename = bundleDir:
    resolveAsbFilepath bundleDir "./deploy.json";

  getImportPath = importDirective:
    if builtins.isAttrs importDirective
      then importDirective.path
    else if builtins.isPath importDirective || builtins.isString importDirective
      then importDirective
    else abort "Unexpected import directive type: '${builtins.typeOf importDirective}'!";

  allowInexistantImport = importDirective:
    if ! builtins.isAttrs importDirective
      then false
    else if importDirective ? allow-inexistent && importDirective.allow-inexistent
      then true
    else false;

  loadBundleImports = bundleDir: importedPaths: opts:
    lib.lists.forEach importedPaths (x:
      let
        relDataPath = getImportPath x;
        absDataPath = resolveAsbFilepath bundleDir relDataPath;
      in
        if allowInexistantImport x
          then loadOptDataDeployBundleOrDefault absDataPath opts
          else loadDataDeployBundle absDataPath opts
    );

  loadDataDeployBundle = bundleDir: opts:
    let
      absFn = resolveDataDeployFilename bundleDir;
    in
      loadDeployFileAt absFn opts;

  loadOptDataDeployBundleOrDefault = bundleDir: opts:
    let
      absFn = resolveDataDeployFilename bundleDir;
    in
      if builtins.pathExists absFn
        then loadDeployFileAt absFn opts
        else mkDefaultBundle bundleDir opts;

  loadUnresolvedBundleListFrom = bundleDir: searchPaths: d: opts:
    let
      imports = getBundleImports bundleDir d opts;
      ds =
        if 0 == builtins.length imports
          then []
          else loadBundleImports bundleDir imports opts;
      rs = if d ? rules then (flattenRules d.rules) else [];
      accFn = acc: subD:
        acc ++ loadUnresolvedBundleListFrom
          subD.bundleDir (searchPaths ++ [subD.bundleDir]) subD opts;
    in
      (builtins.foldl' accFn [] ds) ++ [{
        inherit bundleDir searchPaths;
        rules = rs;
      }];

  loadUnresolvedBundleListFromOpt = bundleDir: searchPaths: d: opts:
    if null == d
      then []
      else loadUnresolvedBundleListFrom bundleDir searchPaths d opts;

  loadDataDeployUnresolvedBundleList = bundleDir: searchPaths: opts:
      loadUnresolvedBundleListFrom bundleDir searchPaths (
        loadDataDeployBundle bundleDir) opts;

  loadOptDataDeployUnresolvedBundleList = bundleDir: searchPaths: opts:
      loadUnresolvedBundleListFrom bundleDir searchPaths (
        loadOptDataDeployBundleOrDefault bundleDir opts) opts;

  resolveFlatRulesSources = unresolvedFlatRules:
    let
      resolve = x:
        if "file" == x.type then {
          inherit (x) target option permission type;
          source = resolveSourceFile x.source x.searchPaths x.option;
        } else if "mkdir" == x.type then {
          inherit (x) target option permission type;
        } else if "rmfile" == x.type then {
          inherit (x) target option type;
        } else
        builtins.abort "Unknown rule type: ${x.type}!";
    in
      filterOutInexistantSources (
        builtins.map resolve unresolvedFlatRules);

  resolveSourceFiles = source: searchPaths:
    let
      accFn = acc: d: let
          p = resolveAsbFilepath d source;
        in if builtins.pathExists p then acc ++ [p] else acc;
      matches = builtins.foldl' accFn [] searchPaths;
    in
      matches;

  prettyPrintSearchPaths = xs:
    lib.strings.concatStringsSep "\n" (
      builtins.map (x: "\"${builtins.toString x}\"") xs);

  resolveSourceFile = source: searchPaths: opts:
    let
      matches = resolveSourceFiles source searchPaths;
    in
      if builtins.length matches >= 1
        then builtins.head matches
        else if opts ? allow-inexistant-source && opts.allow-inexistant-source
          then null
          else builtins.abort ''
            Cannot find source file "${source}" looking in
            the following search paths:
            ${prettyPrintSearchPaths searchPaths}.
          '';

  filterOutInexistantSources = flatRules: let
      pred = x:
        if "file" != x.type
        then assert "mkdir" == x.type || "rmfile" == x.type; true
        else true;
        # TODO: Consider replacing with an rmfile instruction when
        # cannot resolve the file's source or the file's source is
        # null.
        /*
        else if x ? searchPaths
        then null != resolveSourceFile x.source x.searchPaths x.option
        else null != x.source;
        */
    in
      filterOutUnprocessedSourcesOptions(lib.lists.filter pred flatRules);

  filterOutUnprocessedSourcesOptions = flatRules:
    lib.lists.forEach flatRules (x: x // {
      option = lib.attrsets.filterAttrs (
        k: v: k != "allow-inexistant-source") x.option;
    });

  flattenDataDeployBundleList = loadedBundleList:
    assert builtins.isList loadedBundleList;
    let
      extendRulesWithBundleInfo = x:
        assert builtins.isAttrs x;
        assert builtins.isList x.rules;
        lib.lists.forEach x.rules (r:
          r // {
            inherit (x) bundleDir searchPaths;
          }
        );
    in {
      rules = lib.lists.flatten (
        builtins.map extendRulesWithBundleInfo loadedBundleList);
    };

  mkResolvedBundleFromUnresolvedBundle = unresolvedBundle: {
    rules = resolveFlatRulesSources unresolvedBundle.rules;
  };

  loadResolvedDataDeployBundle = bundleDir: opts:
    mkResolvedBundleFromUnresolvedBundle(
      flattenDataDeployBundleList (
        loadOptDataDeployUnresolvedBundleList
          bundleDir [bundleDir] opts
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

  bundleFlatRules = flatRules:
    filterOutEmptyAttrsetsNullOrDefaultValuesWithoutAddedMeaning(
      lib.lists.forEach (
          filterOutInexistantSources flatRules) (x:
        if "file" == x.type then
          # When no source file, matching target should be removed.
          # TODO: Consider a flag for explicitly preventing this.
          if null == x.source then {
            type = "rmfile";
            target = x.target;
            option = {};
          } else {
            inherit (x) target option permission type;
            source = ".${x.target}";
          }
        else if "mkdir" == x.type then {
          inherit (x) target option permission type;
        }
        else if "rmfile" == x.type then {
          inherit (x) target option type;
        }
        else
          builtins.abort "Unknown rule type: ${x.type}!"
      )
    );

  mkDerivationResolvedBundleFromResolvedBundle = resolvedBundle: {
    rules = bundleFlatRules resolvedBundle.rules;
  };

  writeNixSrcVersionJson = srcName: version: runCommand
      "${srcName}-version.json"
      { buildInputs = [ jq ]; } ''
    unformatedVersion="${builtins.toFile "unformatted-version" (builtins.toJSON version)}"
    cat "$unformatedVersion" | jq '.' > "$out"
  '';

  writeToPrettyJson = basename: x: let
    unformatedVersion = builtins.toFile basename (
      builtins.toJSON x);
    in
      runCommand basename {
          buildInputs = [ jq ];
        } ''
        cat "${unformatedVersion}" | jq '.' > "$out"
      '';

  writeResolvedBundleToPrettyJson = basename: resolvedBundle:
    writeToPrettyJson basename resolvedBundle;

  printInstallScriptContent = resolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      mkdir -p "$bundled_rootfs"
    '' +
    lib.strings.concatStringsSep "" (lib.lists.flatten (
      lib.lists.forEach resolvedBundle.rules (x:
        if "file" == x.type then
          lib.lists.optional (null != x.source) ''
            mkdir -p "''${bundled_rootfs}${builtins.dirOf x.target}"
            cp "${x.source}" "''${bundled_rootfs}${x.target}"
          ''
        else assert "mkdir" == x.type || "rmfile" == x.type; []
      )
    ));

  writeRulesInstallScript = resolvedBundle:
    writeShellScript "nixos-sf-data-deploy-install-script" (
      printInstallScriptContent resolvedBundle);

  deployToolsModuleScript = builtins.path {
    path = ./deploy-tools.sh;
    name = "nixos-sf-data-deploy-tools.sh";
  };

  printDeployScriptContent = derivationResolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      out_prefix="''${2:-}"
      . "${deployToolsModuleScript}"

    '' + lib.strings.concatStringsSep "" (lib.lists.flatten (
      lib.lists.forEach derivationResolvedBundle.rules (x:
        let
          options = if x ? option then x.option else {};
          permissions = if x ? permission then x.permission else {};

          owner = lib.strings.concatStrings (lib.lists.take 1 (
            lib.lists.optional (permissions ? user) permissions.user
            ++ lib.lists.optional (permissions ? uid) "${permissions.uid}"));
          ownerGroup = lib.strings.concatStrings (lib.lists.take 1 (
            lib.lists.optional (permissions ? group) permissions.group
            ++ lib.lists.optional (permissions ? gid) "${permissions.gid}"));

          replaceExisting = if options ? replace-existing && null != options.replace-existing
            then options.replace-existing
            else "always";
        in
          # No other values supported yet.
          assert "always" == replaceExisting; (
            if "file" == x.type then
              # Should have already been replaced by a "rmfile" directive.
              assert null != x.source; [''
                deploy_file_w_inherited_access "''${bundled_rootfs}/${x.source}" "''${out_prefix}${x.target}"
              '']
            else if "mkdir" == x.type then [''
                mkdir_w_inherited_access "''${out_prefix}${x.target}"
              '']
            else if "rmfile" == x.type then [''
                rm_file "''${out_prefix}${x.target}"
              '']
            else
              builtins.abort "Unknown rule type: ${x.type}!"
          )
          ++ lib.lists.optional (null != permissions && permissions ? mode) ''
            change_mode "''${out_prefix}${x.target}" "${permissions.mode}"
          ''
          ++ lib.lists.optional (null != permissions
              && (permissions ? user || permissions ? group
                    || permissions ? uid || permissions ? gid)) ''
            change_owner "''${out_prefix}${x.target}" "${owner}" "${ownerGroup}"
          ''
      )));

  writeRulesDeployScript = derivationResolvedBundle:
    writeShellScript "nixos-sf-data-deploy-script" (
      printDeployScriptContent derivationResolvedBundle);


  mkDataDeployDerivationFromResolvedBundle = resolvedBundle:
    let
      rules = resolvedBundle.rules;
      derivationResolvedBundle = mkDerivationResolvedBundleFromResolvedBundle resolvedBundle;
      derivationResolvedBundleJson =
        writeResolvedBundleToPrettyJson "deploy.json" derivationResolvedBundle;
    in
      runCommand "nixos-sf-data-deploy" {
          nativeBuildInputs = [ makeWrapper ];
          buildInputs = [ coreutils ];
        } ''
        mkdir -p "$out"
        bundled_rootfs="$out/share/nixos-sf-data-deploy/rootfs"
        mkdir -p "$bundled_rootfs"
        ${writeRulesInstallScript resolvedBundle} "$bundled_rootfs"
        cp ${derivationResolvedBundleJson} "$bundled_rootfs/deploy.json"

        mkdir -p "$out/bin"

        makeWrapper \
          "${writeRulesDeployScript derivationResolvedBundle}" \
          "$out/bin/nixos-sf-data-deploy" \
          --add-flags "$bundled_rootfs"
      '';

  mkDataDeployDerivationFromUnresolvedBundle = unresolvedBundle:
    let
      resolvedBundle = mkResolvedBundleFromUnresolvedBundle unresolvedBundle;
    in
      mkDataDeployDerivationFromResolvedBundle resolvedBundle;



  mkDataDeployDerivation = dataDir: options:
    let
      bundle = loadResolvedDataDeployBundle dataDir options;
      drv = mkDataDeployDerivationFromResolvedBundle bundle;
    in
      drv;
in

rec {
  impl = {
    inherit loadDataDeployBundle loadOptDataDeployBundleOrDefault;
    inherit loadDataDeployUnresolvedBundleList loadOptDataDeployUnresolvedBundleList;
    inherit flattenDataDeployBundleList;
    inherit mkResolvedBundleFromUnresolvedBundle mkDerivationResolvedBundleFromResolvedBundle;
    inherit loadResolvedDataDeployBundle;
    inherit writeToPrettyJson writeResolvedBundleToPrettyJson;
    inherit writeRulesInstallScript writeRulesDeployScript;
    inherit mkDataDeployDerivationFromResolvedBundle mkDataDeployDerivationFromUnresolvedBundle;
  };

  inherit mkDataDeployDerivation;
}
