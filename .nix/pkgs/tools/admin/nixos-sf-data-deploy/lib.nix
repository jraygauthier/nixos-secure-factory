
{ lib
, writeShellScript
, runCommand
, coreutils
, makeWrapper
, jq
, nixos-sf-deploy-core-nix-lib
, nixos-sf-data-deploy-tools
}:

with nixos-sf-deploy-core-nix-lib;

let
  perRuleTypeSchema = {
    "file" = true;
    "mkdir" = true;
    "rmfile" = true;
  };

  assertValidRuleSchema =
    assertValidRuleSchemaImpl perRuleTypeSchema assertOptsWPropagatedBundleAttrs;

  resolveFlatRulesSources = unresolvedFlatRules:
    let
      resolve = x:
        if "file" == x.type then x // {
          source = resolveSourceFile x.source x.searchPaths x.option;
        }
        else
          assertValidRuleSchema x;
    in
      filterOutSourceResolverOptions (
        filterOutPropagatedBundleAttrsFromFlatRules(
          builtins.map resolve unresolvedFlatRules));

  mkResolvedBundleFromUnresolvedBundle = unresolvedBundle: {
    rules = resolveFlatRulesSources unresolvedBundle.rules;
  };

  loadResolvedDataDeployBundle = bundleDir: bOpts:
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

  bundleFlatRules = flatRules:
    filterOutEmptyAttrsetsNullOrDefaultValuesWithoutAddedMeaning(
      lib.lists.forEach (
          filterOutSourceResolverOptions flatRules) (x:
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

  printDeployScriptContent = derivationResolvedBundle: ''
      set -euf -o pipefail
      bundled_rootfs="''${1?}"
      out_prefix="''${2:-}"

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
                nsf-file-deploy-w-inherited-permissions "''${bundled_rootfs}/${x.source}" "''${out_prefix}${x.target}"
              '']
            else if "mkdir" == x.type then [''
                nsf-dir-mk-w-inherited-permissions "''${out_prefix}${x.target}"
              '']
            else if "rmfile" == x.type then [''
                nsf-file-rm "''${out_prefix}${x.target}"
              '']
            else
              builtins.abort "Unknown rule type: ${x.type}!"
          )
          ++ lib.lists.optional (null != permissions && permissions ? mode) ''
            nsf-file-chmod "''${out_prefix}${x.target}" "${permissions.mode}"
          ''
          ++ lib.lists.optional (null != permissions
              && (permissions ? user || permissions ? group
                    || permissions ? uid || permissions ? gid)) ''
            nsf-file-chown "''${out_prefix}${x.target}" "${owner}" "${ownerGroup}"
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
        writeToPrettyJson "deploy.json" derivationResolvedBundle;

      rulesInstallScriptDeps = [ coreutils ];
      rulesDeployScriptDeps = [ nixos-sf-data-deploy-tools ];

    in
      runCommand "nixos-sf-data-deploy" {
          nativeBuildInputs = [
            makeWrapper
          ] ++ rulesInstallScriptDeps;
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
          --prefix PATH : ${lib.makeBinPath rulesDeployScriptDeps} \
          --add-flags "$bundled_rootfs"
      '';

  mkDataDeployDerivation = dataDir: bOpts:
    let
      bundle = loadResolvedDataDeployBundle dataDir bOpts;
      drv = mkDataDeployDerivationFromResolvedBundle bundle;
    in
      drv;

  mkDataDeployPackage =
      { bundleDir
      , defaultImportsFn ? bundleDir: []
      }:
    mkDataDeployDerivation bundleDir {
      inherit defaultImportsFn;
    };
in

rec {
  impl = {
    inherit mkResolvedBundleFromUnresolvedBundle mkDerivationResolvedBundleFromResolvedBundle;
    inherit loadResolvedDataDeployBundle;
    inherit writeRulesInstallScript writeRulesDeployScript;
    inherit mkDataDeployDerivationFromResolvedBundle;
  };

  inherit mkDataDeployDerivation mkDataDeployPackage;
}
