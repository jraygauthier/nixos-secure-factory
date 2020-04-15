
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  sshAuthLoader = callPackage ./ssh-auth-loader.nix {};
in

with sshAuthLoader;

rec {
  defUsersRawAttrs = {
    ssh-users = {};
  };


  loadUsersRawAttrs = dCfg: dir:
    loadAttrs dCfg.dirLayout.fileFormat dir dCfg.dirLayout.users defUsersRawAttrs;


  resolveStrWUserVarExpansion = user: str:
    builtins.replaceStrings ["\${ssh-user.name}"] ["${user.name}"] str;


  getUserDefaults = defUserDefaults: loadedRawAttrs:
      let
        ud = if loadedRawAttrs ? "ssh-user-defaults"
          then loadedRawAttrs.ssh-user-defaults
          else {};
      in
    defUserDefaults // ud;


  ensureListOrIfStrMkSingleton = inVal:
    # Similiarly to `lib.lists.toList` but only applies to strings.
    if builtins.isString inVal
    then [ inVal ]
    else assert (builtins.isList inVal); inVal;


  mergeUsersAttrs = umPol: x: y:
      assert builtins.isAttrs x;
      assert builtins.isAttrs y;
      let
        checkAllSameUserSamePubKey = lib.lists.all (x: x == true) (
            lib.attrsets.mapAttrsToList(k: _:
                  let
                    xu = x."${k}";
                    yu = y."${k}";
                    xPkf = xu.pubkey.file;
                    yPkf = yu.pubkey.file;
                    samePubkey = xPkf == yPkf;
                    pksStr = "${builtins.toString xPkf}\n${builtins.toString yPkf}";
                  in
                assert lib.asserts.assertMsg samePubkey
                  "Merge policy does not allow us to merge user '${k}' from '${xu.srcStr}' with user '${k}' from '${yu.srcStr}'. "
                  "Those users have mismatching public key files: ''\n${pksStr}\n''";
                samePubkey
              )
              (builtins.intersectAttrs x y)
          );
      in
    assert umPol.allowSilentMergeMismatchingPubKeys || checkAllSameUserSamePubKey;
    # Remember that rightmost has priority over leftmost when same key.
    lib.trivial.mergeAttrs x y;


  mergeListOfUsersAttrs = umPol: xs:
    lib.lists.foldl' lib.trivial.mergeAttrs {} xs;


  mergeListOfUsers = mPol: xs: {
    srcs = lib.lists.concatLists (builtins.map (x: x.srcs) xs);
    sshUsers = mergeListOfUsersAttrs mPol.user (builtins.map (x: x.sshUsers) xs);
  };


  resolveUserDefaults = defUserDefaultsRawAttr: loadedRawAttrs:
      let
        userDefaults = getUserDefaults defUserDefaultsRawAttr loadedRawAttrs;
      in
    {
      pubkey.locations = user:
          let
            userOrDef = userDefaults // user;
            rawTemplates = ensureListOrIfStrMkSingleton userOrDef.pubkey-file-template;
            rawSearchPaths = ensureListOrIfStrMkSingleton userOrDef.pubkey-file-search-path;

            basenames = lib.lists.forEach rawTemplates (x:
              resolveStrWUserVarExpansion user x
            );

            resolveRelPath = rp:
              (getSingleSrcDir loadedRawAttrs.srcs) + "/${rp}";

            searchPaths = builtins.map resolveRelPath rawSearchPaths;

            locations =
              if userOrDef ? pubkey-file
              then [ (resolveRelPath userOrDef.pubkey-file) ]
              else
                lib.lists.concatMap (
                    sp: map (bn: sp + "/${bn}") basenames
                  )
                  searchPaths;
          in
        locations;
    };


  resolveUsers = userDef: usersRawAttrs:
      assert usersRawAttrs ? "ssh-users"; # TODO: Improve error.
      let
        users = lib.attrsets.mapAttrs (uk: uv:
            let
              rawUser = uv // { name = uk; };
              pkLocs = userDef.pubkey.locations rawUser;
              pkLocsStr = lib.strings.concatStringsSep "\n" (builtins.map builtins.toString pkLocs);
              pkFile = lib.lists.findFirst (pkLoc: builtins.pathExists pkLoc) null pkLocs;
              srcPathStr = printSrcPaths usersRawAttrs.srcs;
            in assert lib.asserts.assertMsg (pkFile != null)
                ( "Cannot resolve public key for user '${uk}' defined in '${srcPathStr}'.\n"
                + "The following locations were looked up: ''\n${pkLocsStr}\n''"
                );
              {
                pubkey.file = pkFile;
                # This is only used to improve merge errors. See `mergeUsersAttrs`.
                srcStr = srcPathStr;
              }
          )
          usersRawAttrs.ssh-users;
      in {
      inherit (usersRawAttrs) srcs;
      sshUsers = users;
    };


  loadUsersExtra' = dCfg: dir: userDefFromDir: qualifierStr: extraRawAttrs:
    assert null != extraRawAttrs;
      let
        rawAttrs = extendAttrsWSrcsInfo
          dir "in-memory-user-extra-${qualifierStr}" [] extraRawAttrs;
        userDef = if rawAttrs ? "ssh-user-defaults"
          then
            resolveUserDefaults dCfg.userDefaultsRawAttr rawAttrs
          else
            # When extra users are specified without their own defaults
            # specification, we inherit from the dir's loaded defaults
            # instead of the defaults from the config. This should
            # allow for reliable retrieval of pub keys in the dir.
            userDefFromDir;
      in
    resolveUsers userDef rawAttrs;


  loadUsersExtra = dCfg: dir: qualifierStr: extraRawAttrs:
    loadUsersExtra'
      dCfg dir (resolveUserDefaults dCfg.userDefaultsRawAttr rawAttrs)
      qualifierStr extraRawAttrs;


  loadUsersWExtra = dCfg: dir: {
      extraUsersInherited ? null,
      extraUsersOverride ? null
    }:
      let
        rawAttrs = loadUsersRawAttrs dCfg dir;
        userDef = resolveUserDefaults dCfg.userDefaultsRawAttr rawAttrs;
      in
    mergeListOfUsers dCfg.mergePolicy (
          lib.lists.optional (null != extraUsersInherited) (
            loadUsersExtra' dCfg dir userDef "inherited" extraUsersInherited
          )
      ++  [ (resolveUsers userDef rawAttrs) ]
      ++  lib.lists.optional (null != extraUsersOverride) (
            loadUsersExtra' dCfg dir userDef "override" extraUsersOverride
          )
      );


  loadUsers = dCfg: dir:
    loadUsersWExtra dCfg dir {};



}
