
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  coreModule = callPackage ./core.nix {};
  loaderModule = callPackage ./loader.nix {};
in

with coreModule;
with loaderModule;

rec {
  defUserDefaultsRawAttr = {
    pubkey-file-template = [
      "\${ssh-user.name}.pub"
    ];
    pubkey-file-search-path = [
      "./public-keys"
    ];
  };

  defUsersRawAttrs = {
    ssh-users = {};
  };


  loadUsersRawAttrs = dCfg: dir:
    loadAttrs dCfg.dir-layout.file-format dir dCfg.dir-layout.users defUsersRawAttrs;


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


  isSshUsers = users:
    users ? "sshUsers";


  isSshUsersValue = users:
    users ? "pubkey" && users.pubkey ? "file";


  mkSshUsers = usersAttrSet: {
    sshUsers = lib.attrsets.mapAttrs (k: v:
        assert isSshUsersValue v;
        v
      )
      usersAttrSet;
  };


  listUserNamesForSshUsers = users:
    assert isSshUsers users;
    lib.attrsets.mapAttrsToList (k: v: k) users.sshUsers;


  mkSshUsernamesForSshUsers = users: {
      sshUsernames = listUserNamesForSshUsers users;
    };


  listPubKeysForSshUsers = users:
    assert isSshUsers users;
    lib.attrsets.mapAttrsToList (k: v: v.pubkey.file) users.sshUsers;


  listPubKeysContentForSshUsers = users:
    map builtins.readFile (listPubKeysForSshUsers users);


  mkSshPubKeysForSshUsers = users: {
      sshPubKeys = listPubKeysForSshUsers users;
    };


  ensureValidMPolMergeMismatchingPukeyCfg = {
        allow ? false
      }:
    {
      inherit allow;
    };


  defMPolMergeMismatchingPukeyCfg = ensureValidMPolMergeMismatchingPukeyCfg {};


  ensureValidMPolUserPubkeyCfg = {
        merge-mismatching ? defMPolMergeMismatchingPukeyCfg
      }:
    {
      merge-mismatching = ensureValidMPolMergeMismatchingPukeyCfg merge-mismatching;
    };


  defMPolUserPubkeyCfg = ensureValidMPolUserPubkeyCfg {};


  ensureValidUsersMergePolicy = {
        pubkey ? defMPolUserPubkeyCfg
      }:
    {
      pubkey = ensureValidMPolUserPubkeyCfg pubkey;
    };


  defUsersMergePolicy = ensureValidUsersMergePolicy {};


  inheritedUsersMergePolicy = ensureValidUsersMergePolicy {
      pubkey.merge-mismatching.allow = true;
    };


  overrideUsersMergePolicy = ensureValidUsersMergePolicy {
      pubkey.merge-mismatching.allow = true;
    };


  printMismatchingSshUserPubKeys = xu: yu:
      let
        xPkf = xu.pubkey.file;
        yPkf = yu.pubkey.file;
        pksStr = "${builtins.toString xPkf}\n${builtins.toString yPkf}";
      in
    pksStr;


  defOnDisallowedSameSshUserPubkeyMsg = uName: xu: yu:
        "Merge policy does not allow us to merge user '${uName}' from '${xu.srcStr}' with user '${uName}' from '${yu.srcStr}'. "
      + "Those users have mismatching public key files: ''\n${printMismatchingSshUserPubKeys xu yu}\n''";


  defUsersMergeOpts = {};


  mergeSameNameUsers = umPol: {
        onDisallowedSameSshUserPubkeyMsg ? defOnDisallowedSameSshUserPubkeyMsg
      }:
      uName: xu: yu:
    assert isSshUsersValue xu;
    assert isSshUsersValue yu;
      let
        umPolValid = ensureValidUsersMergePolicy umPol;
        pksStr = printMismatchingSshUserPubKeys xu yu;
        xPkf = xu.pubkey.file;
        yPkf = yu.pubkey.file;
        samePubkey = xPkf == yPkf;
      in
    assert lib.asserts.assertMsg (umPolValid.pubkey.merge-mismatching.allow || samePubkey) (
        onDisallowedSameSshUserPubkeyMsg uName xu yu
      );
    {
      # Remember that rightmost has priority over leftmost when same key.
      # Note here that it is alright for the srcStr to take only the rhs
      # as only the rhs pubkey will be preserved (this is not a real merge
      # but an override).
      pubkey.file = yu.pubkey.file;
      srcStr = yu.srcStr;
    };


  mergeSameNameUserList = umPol: opts: uName: uValues:
    assert 1 <= lib.lists.length uValues;
    lib.lists.foldl' (mergeSameNameUsers umPol opts uName) (lib.lists.head uValues) (lib.lists.tail uValues);


  mergeUserAttrSets = umPol: opts: uSetA: uSetB:
      assert builtins.isAttrs uSetA;
      assert builtins.isAttrs uSetB;

      # Remember that rightmost has priority over leftmost when same key.
      lib.attrsets.zipAttrsWith (mergeSameNameUserList umPol opts) [ uSetA uSetB ];


  mergeListOfUserAttrSets = umPol: opts: xs:
    lib.lists.foldl' (mergeUserAttrSets umPol opts) {} xs;


  mergeListOfUserBundles = umPol: xs: {
    srcs = lib.lists.concatLists (builtins.map (x: x.srcs) xs);
    sshUsers = mergeListOfUserAttrSets umPol defUsersMergeOpts (builtins.map (x: x.sshUsers) xs);
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
              if builtins.isPath rp
                # Should not be prefixed by source file dir as it is relative
                # to the source nix file.
                then rp
              else if lib.strings.hasPrefix builtins.storeDir (builtins.toString rp)
                # Definitively a abs path. Should not be appeded to a path as
                # otherwise we will receive the following error:
                # "error: a string that refers to a store path cannot be appended to a path, at."
                then rp
              else if lib.strings.hasPrefix "/" (builtins.toString rp)
                # Absoluate path as strings should be returned as a corresponding
                # nix path.
                then /. + rp
              else
                # This is a relative path.
                # Transform this relative path to a nix path by prepending the
                # dirname of the loaded users file to it.
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
              srcPathStr = printSrcStrForSrcs usersRawAttrs.srcs;
            in assert lib.asserts.assertMsg (pkFile != null)
                ( "Cannot resolve public key for user '${uk}' defined in '${srcPathStr}'.\n"
                + "The following locations were looked up: ''\n${pkLocsStr}\n''"
                );
              {
                pubkey.file = pkFile;
                # This is only used to improve merge errors. See `mergeUserAttrSets`.
                srcStr = srcPathStr;
              }
          )
          usersRawAttrs.ssh-users;
      in {
      inherit (usersRawAttrs) srcs;
      sshUsers = users;
    };


  loadUsersRawExtra' = dCfg: dir: userDefFromDir: qualifierStr: extraRawAttrs:
    assert null != extraRawAttrs;
      let
        rawAttrs = extendAttrsWSrcsInfo
          dir "in-memory-user-extra-raw-${qualifierStr}" [] extraRawAttrs;
        userDef = if rawAttrs ? "ssh-user-defaults"
          then
            resolveUserDefaults dCfg.user-defaults-raw-attr rawAttrs
          else
            # When extra users are specified without their own defaults
            # specification, we inherit from the dir's loaded defaults
            # instead of the defaults from the config. This should
            # allow for reliable retrieval of pub keys in the dir.
            userDefFromDir;
      in
    resolveUsers userDef rawAttrs;


  loadUsersRawExtra = dCfg: dir: qualifierStr: extraRawAttrs:
    loadUsersRawExtra'
      dCfg dir (resolveUserDefaults dCfg.user-defaults-raw-attr rawAttrs)
      qualifierStr extraRawAttrs;


  loadUsersPlain = dCfg: dir:
      let
        rawAttrs = loadUsersRawAttrs dCfg dir;
        userDef = resolveUserDefaults dCfg.user-defaults-raw-attr rawAttrs;
      in
    resolveUsers userDef rawAttrs;


  loadUsersWExtra = dCfg: dir: {
      extraUsers ? {}
    }:
      let
        rawAttrs = loadUsersRawAttrs dCfg dir;
        userDef = resolveUserDefaults dCfg.user-defaults-raw-attr rawAttrs;
      in
    mergePlainWExtra
      (resolveUsers userDef rawAttrs)
      extraUsers
      {
        inherited = {
          mergeLOf = mergeListOfUserBundles dCfg.merge-policy.ssh-user.inherited;
          loadExtra = loadUsersRawExtra' dCfg dir userDef "inherited";
        };
        override = {
          mergeLOf = mergeListOfUserBundles dCfg.merge-policy.ssh-user.override;
          loadExtra = loadUsersRawExtra' dCfg dir userDef "override";
        };
      };


  loadUsers = dCfg: dir:
    loadUsersWExtra dCfg dir {};
}
