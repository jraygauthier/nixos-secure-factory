
{ nixpkgs ? <nixpkgs> }:

let
  inherit (nixpkgs) lib writeShellScript runCommand coreutils makeWrapper jq;

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
          rulesListFillMissing (v // {
            target = k;
          })
        ) x;

    in
      # Support both attrset rules and list rules.
      if lib.isList loadedRules
        then rulesListFillMissing loadedRules
        else rulesAttr2List loadedRules;

  loadDeployFileAt = absFn:
    let
      fnCwd = builtins.dirOf absFn;
    in
      builtins.fromJSON (builtins.readFile absFn) // { bundleDir = fnCwd; };

  resolveDataDeployFilename = bundleDir:
    resolveAsbFilepath bundleDir "./deploy.json";

  loadBundleImports = bundleDir: importedPaths:
    builtins.map (x: loadDataDeployBundle (resolveAsbFilepath bundleDir x)) importedPaths;

  loadDataDeployBundle = bundleDir:
    let
      absFn = resolveDataDeployFilename bundleDir;
    in
      loadDeployFileAt absFn;

  loadOptDataDeployBundleOrNull = bundleDir:
    let
      absFn = resolveDataDeployFilename bundleDir;
    in
      if builtins.pathExists absFn
        then loadDeployFileAt absFn
        else null;

  loadUnresolvedBundleListFrom = bundleDir: searchPaths: d:
    let
      ds = if d ? imports then loadBundleImports bundleDir d.imports else [];
      rs = if d ? rules then (flattenRules d.rules) else [];
      accFn = acc: subD:
        acc ++ loadUnresolvedBundleListFrom subD.bundleDir (searchPaths ++ [subD.bundleDir]) subD;
    in
      (builtins.foldl' accFn [] ds) ++ [{
        inherit bundleDir searchPaths;
        rules = rs;
      }];

  loadUnresolvedBundleListFromOpt = bundleDir: searchPaths: d:
    if null == d then [] else loadUnresolvedBundleListFrom bundleDir searchPaths d;

  loadDataDeployUnresolvedBundleList = bundleDir: searchPaths:
      loadUnresolvedBundleListFrom bundleDir searchPaths (
        loadDataDeployBundle bundleDir);

  loadOptDataDeployUnresolvedBundleList = bundleDir: searchPaths:
      loadUnresolvedBundleListFromOpt bundleDir searchPaths (
        loadOptDataDeployBundleOrNull bundleDir);

  resolveFlatRulesSources = unresolvedFlatRules: let
      resolve = x:
      if "file" == x.type then {
        inherit (x) target option permission type;
        source = resolveSourceFile x.source x.searchPaths x.option;
      } else if "mkdir" == x.type then {
        inherit (x) target option permission type;
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

  resolveSourceFile = source: searchPaths: opts: let
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
        then assert "mkdir" == x.type; true
        else if x ? searchPaths
        then null != resolveSourceFile x.source x.searchPaths x.option
        else null != x.source;
    in
      filterOutUnprocessedSourcesOptions(lib.lists.filter pred flatRules);

  filterOutUnprocessedSourcesOptions = flatRules:
    lib.lists.forEach flatRules (x: x // {
      option = lib.attrsets.filterAttrs (
        k: v: k != "allow-inexistant-source") x.option;
    });

  flattenDeviceDataBundleList = loadedBundleList:
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
        if "file" == x.type then {
          inherit (x) target option permission type;
          source = ".${x.target}";
        } else if "mkdir" == x.type then {
          inherit (x) target option permission type;
        } else
        builtins.abort "Unknown rule type: ${x.type}!"
      )
    );

  mkDerivationResolvedBundleFromResolvedBundle = resolvedBundle: {
    rules = bundleFlatRules resolvedBundle.rules;
  };

  writeNixSrcVersionJson = srcName: version: nixpkgs.runCommand
      "${srcName}-version.json"
      { buildInputs = [ nixpkgs.jq ]; } ''
    unformatedVersion="${builtins.toFile "unformatted-version" (builtins.toJSON version)}"
    cat "$unformatedVersion" | jq '.' > "$out"
  '';

  writeToPrettyJson = basename: x: let
    unformatedVersion = builtins.toFile basename (
      builtins.toJSON x);
    in
      nixpkgs.runCommand basename {
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
        else assert "mkdir" == x.type; []
      )
    ));

  writeRulesInstallScript = resolvedBundle:
    writeShellScript "nixos-sf-data-deploy-install-script" (
      printInstallScriptContent resolvedBundle);

  writeRulesDeployToolsModuleScript =
    writeShellScript "nixos-sf-data-deploy-install-script" ''
      mkdir_w_inherited_access() {
        local in_dir="''${1?}"

        local to_be_created=()
        if ! [[ -d "$in_dir" ]]; then
          to_be_created=( "$in_dir" "''${to_be_created[@]}" )
        fi

        local p_dir
        p_dir="$(dirname "$in_dir")"

        while [[ "''${#p_dir}" -gt 1 ]] \
            && ! [[ -d "$p_dir" ]]; do
          to_be_created=( "$p_dir" "''${to_be_created[@]}" )
          p_dir="$(dirname "$p_dir")"
        done

        if ! [[ -d "$p_dir" ]]; then
          1>&2 echo "ERROR: find_first_existing_parent_dir: No parent dir for '$in_dir'."
          return 1
        fi

        local oct_mode
        oct_mode="$(stat -c '%a' "$p_dir")"
        local uid
        uid="$(stat -c '%u' "$p_dir")"
        local gid
        gid="$(stat -c '%g' "$p_dir")"

        for d in "''${to_be_created[@]}"; do
          local mkdir_args=( -m "$oct_mode" "$d" )
          echo mkdir "''${mkdir_args[@]}"
          mkdir "''${mkdir_args[@]}"
          local chown_args=( "''${uid}:''${gid}" "$d" )
          echo chown "''${chown_args[@]}"
          chown "''${chown_args[@]}"
        done
      }

      deploy_file_w_inherited_access() {
        local src_file="''${1?}"
        local tgt_file="''${2?}"

        local tgt_dir
        tgt_dir="$(dirname "$tgt_file")"
        mkdir_w_inherited_access "$tgt_dir"

        local oct_mode
        oct_mode="$(stat -c '%a' "$tgt_dir")"
        local uid
        uid="$(stat -c '%u' "$tgt_dir")"
        local gid
        gid="$(stat -c '%g' "$tgt_dir")"

        local cp_args=( "$src_file" "$tgt_file" )
        echo cp "''${cp_args[@]}"
        cp "''${cp_args[@]}"

        local chmod_args=( "$oct_mode" "$tgt_file" )
        echo chmod "''${chmod_args[@]}"
        chmod "''${chmod_args[@]}"

        local chown_args=( "''${uid}:''${gid}" "$tgt_file" )
        echo chown "''${chown_args[@]}"
        chown "''${chown_args[@]}"
      }


      change_mode() {
        local tgt_file="''${1?}"
        local new_mode="''${2?}"
        local chmod_args=( "$new_mode" "$tgt_file" )
        echo chmod "''${chmod_args[@]}"
        chmod "''${chmod_args[@]}"
      }


      change_owner() {
        local tgt_file="''${1?}"
        local new_owner="''${2:-}"
        local new_owner_group="''${3:-}"

        previous_uid="$(stat -c '%u' "$tgt_file")"
        local owner="''${new_owner:-"$previous_uid"}"

        previous_gid="$(stat -c '%g' "$tgt_file")"
        local group="''${new_owner_group:-"$previous_gid"}"

        chown_args=( "''${owner}:''${group}" "$tgt_file" )
        echo chown "''${chown_args[@]}"
        chown "''${chown_args[@]}"
      }
      '';

  printDeployScriptContent = derivationResolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      out_prefix="''${2:-}"
      . "${writeRulesDeployToolsModuleScript}"

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
              lib.lists.optional (null != x.source) ''
                deploy_file_w_inherited_access "''${bundled_rootfs}/${x.source}" "''${out_prefix}${x.target}"
              ''
            else if "mkdir" == x.type then [''
                mkdir_w_inherited_access "''${out_prefix}${x.target}"
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


  mkDataDeployDerivationFromUnresolvedBundle = unresolvedBundle:
    let
      resolvedBundle = mkResolvedBundleFromUnresolvedBundle unresolvedBundle;
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
in

rec {
  inherit loadDataDeployBundle loadOptDataDeployBundleOrNull;
  inherit loadDataDeployUnresolvedBundleList loadOptDataDeployUnresolvedBundleList;
  inherit flattenDeviceDataBundleList;
  inherit mkResolvedBundleFromUnresolvedBundle mkDerivationResolvedBundleFromResolvedBundle;
  inherit writeToPrettyJson writeResolvedBundleToPrettyJson;
  inherit mkDataDeployDerivationFromUnresolvedBundle;
}
