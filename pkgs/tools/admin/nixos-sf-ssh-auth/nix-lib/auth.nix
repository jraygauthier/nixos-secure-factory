
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  coreModule = callPackage ./core.nix {};
  loaderModule = callPackage ./loader.nix {};
  usersModule = callPackage ./users.nix {};
  groupsModule = callPackage ./groups.nix {};
  authModule = callPackage ./auth.nix {};
in

with coreModule;
with loaderModule;
with usersModule;
with groupsModule;
with authModule;

rec {

  validMergeMismatchingAuthorizedSshUserSetMethodFieldValues =
    [
      "whole-override"
      "piecewise-mix"
    ];


  validMergeMismatchingAuthorizedSshUserSetMethodFieldValuesWDefault =
    ["default"] ++ validMergeMismatchingAuthorizedSshUserSetMethodFieldValues;


  ensureValidMergeMismatchingAuthorizedSshUserSetCfg = {
        # When disabled, an error will be raised when mismatching authorized ssh user
        # sets are found.
        allow ? false,
        method ? "default"  # Is 'whole-override'.
        # 'whole-override':
        #   For 2 *device users* with same name, the rhs *auth ssh user set*
        #   is always preserved / override entirely the lhs set.
        # 'piecewise-mix':
        #   For 2 *device users* with same name, when the *authorized ssh user set*
        #   is found to be different, those set will be allowed to intermingle
        #   according to the above `ssh-user` merge policy. By default, for a same
        #   name user the rhs win (i.e: rhs pub key is preserved).
        #   IMPORTANT: With this option on, lhs users can be injected into
        #   the rhs authorized set which *breaks the integrity* of rhs.
      }:
      let
        resolvedDefaultValue = "whole-override";
        validMethods = validMergeMismatchingAuthorizedSshUserSetMethodFieldValuesWDefault;
        methodIsValid = lib.lists.elem method validMethods;
        validMethodsStr = lib.strings.concatStringsSep "\n" validMethods;
      in
    assert lib.asserts.assertMsg (methodIsValid)
      ( "Invalid \"authorized-set.merge-mismatching.method\" field value. "
      + "Expected one of the following: ''\n${validMethodsStr}\n''");
      let
        resolvedMethod = if "default" == method
          then resolvedDefaultValue
          else method;
      in
    {
      inherit allow;
      method = resolvedMethod;
    };


  defMergeMismatchingAuthorizedSshUserSetCfg = ensureValidMergeMismatchingAuthorizedSshUserSetCfg {};


  ensureValidMPolDeviceUserAuthorizedSetCfg = {
        merge-mismatching ? defMergeMismatchingAuthorizedSshUserSetCfg,
      }:
    {
      merge-mismatching =
        ensureValidMergeMismatchingAuthorizedSshUserSetCfg merge-mismatching;
    };


  defMPolDeviceUserAuthorizedSetCfg = ensureValidMPolDeviceUserAuthorizedSetCfg {};


  ensureValidAuthMergePolicy = {
        # How to merge ssh users when merging 2 auth.
        ssh-user ? defUsersMergePolicy,
        authorized-set ? defMPolDeviceUserAuthorizedSetCfg,
      }:
    {
      ssh-user = ensureValidUsersMergePolicy ssh-user;
      authorized-set =
        ensureValidMPolDeviceUserAuthorizedSetCfg authorized-set;
    };


  defAuthMergePolicy = ensureValidAuthMergePolicy {};


  inheritedAuthMergePolicy = ensureValidAuthMergePolicy {
    ssh-user = inheritedUsersMergePolicy;
    authorized-set.merge-mismatching.allow = true;
  };


  overrideAuthMergePolicy = ensureValidAuthMergePolicy {
    ssh-user = overrideUsersMergePolicy;
    authorized-set.merge-mismatching.allow = true;
  };


  inheritedAuthMergePolicyWPiecewise = ensureValidAuthMergePolicy {
      ssh-user = inheritedUsersMergePolicy;
      authorized-set.merge-mismatching = {
          allow = true;
          method = "piecewise-mix";
        };
    };


  overrideAuthMergePolicyWPiecewise = ensureValidAuthMergePolicy {
      ssh-user = overrideUsersMergePolicy;
      authorized-set.merge-mismatching = {
          allow = true;
          method = "piecewise-mix";
        };
    };


  internalAuthMergePolicy = ensureValidAuthMergePolicy {
      authorized-set.merge-mismatching = {
          allow = true;
          method = "piecewise-mix";
        };
    };


  defAuthRawAttrs = {
    device-users = {};
  };


  isDeviceUserValue = deviceUserValue:
    deviceUserValue ? "sshUsers";


  defOnDisallowedMergeMismatchingDeviceUserAuthSshUserSetMsg = duName: xdu: ydu:
      "Merge policy does not allow us to merge \"device user\" '${duName}' from "
    + "'${xdu.srcStr}' with \"device user\" '${duName}' from '${ydu.srcStr}'. "
    + "Those \"device users\" have mismatching \"authorized ssh user set\": "
    + "''\n${printAttrsetKeysDiffStr xdu.sshUsers ydu.sshUsers}\n''";


  defDeviceUsersMergeOpts = {};


  mergeSameNameDeviceUsers = amPol: opts: duName: xdu: ydu:
    assert isDeviceUserValue xdu;
    assert isDeviceUserValue ydu;
      let
        amPolValid = ensureValidAuthMergePolicy amPol;
        allowMergeMismatching =
            amPolValid.authorized-set.merge-mismatching.allow;

        sameUsrKs = attrsetSameKeys xdu.sshUsers ydu.sshUsers;
      in
    assert lib.asserts.assertMsg (allowMergeMismatching || sameUsrKs) (
        defOnDisallowedMergeMismatchingDeviceUserAuthSshUserSetMsg duName xdu ydu
      );

    if sameUsrKs
      then
        # Lhs does not bring anything new to the table so rhs's memberset is taken as a whole
        # diregarding lhs.
        ydu
    else if "piecewise-mix" == amPolValid.authorized-set.merge-mismatching.method
      then
        {
          # Some part of lhs's memberset is allowed to be injected into rhs according to
          # current `ssh-user` policy (by default a rhs user will override the lhs user as a whole).
          # See `ensureValidAuthMergePolicy` important comment about this option's security.
          # TODO: specialize `defUsersMergeOpts` in order to get better error message.
          sshUsers = mergeUserAttrSets amPolValid.ssh-user defUsersMergeOpts xdu.sshUsers ydu.sshUsers;
          srcStr = mergeSrcStrList [xdu.srcStr ydu.srcStr];
        }
    else
      assert "whole-override" == amPolValid.authorized-set.merge-mismatching.method;
      # Rhs's *authorized ssh user set* is chosen as a whole.
      ydu;


  mergeSameNameDeviceUserList = amPol: opts: duName: duValues:
    assert 1 <= lib.lists.length duValues;
    lib.lists.foldl' (mergeSameNameDeviceUsers amPol opts duName) (lib.lists.head duValues) (lib.lists.tail duValues);


  mergeDeviceUserAttrSets = amPol: opts: duSetA: duSetB:
      assert builtins.isAttrs duSetA;
      assert builtins.isAttrs duSetB;
    # Remember that rightmost has priority over leftmost when same key.
    lib.attrsets.zipAttrsWith (mergeSameNameDeviceUserList amPol opts) [ duSetA duSetB ];


  mergeListOfDeviceUserAttrSets = amPol: xs:
    lib.lists.foldl' (mergeDeviceUserAttrSets amPol defDeviceUsersMergeOpts) {} xs;


  mergeListOfAuthBundles = amPol: xs:
    {
      srcs = lib.lists.concatLists (builtins.map (x: x.srcs) xs);
      deviceUsers = mergeListOfDeviceUserAttrSets amPol
        (builtins.map (x: x.deviceUsers) xs);
    };


  mergeDeviceUserAuthorizedSshGroupsAndUsersAsSshUsersBundle = amPol: listOfSshGroupBundles: sshUsersBundle:
    {
      # TODO: Specialize `defUsersMergeOpts`  in order to print improved error messages.
      sshUsers = mergeListOfUserAttrSets amPol.sshUsers defUsersMergeOpts (
            (lib.attrsets.mapAttrsToList (k: v: v.members) listOfSshGroupBundles)
         ++ [ sshUsersBundle ]
        );
    };

  resolveAuthUsersFromSshUsers = deviceUserName: authSrcFile: usersSrcFile:
    cherryPickFromAttrs (onGenMissingAttr "device user" deviceUserName authSrcFile "authorized user" "user attrset" usersSrcFile);


  resolveAuthGroupFromSshGroups = deviceUserName: authSrcFile: groupsSrcFile:
    cherryPickFromAttrs (onGenMissingAttr "device user" deviceUserName authSrcFile "authorized group" "group attrset" groupsSrcFile);


  resolveAuth = mPol: users: groups: authRawAttrs:
      assert authRawAttrs ? "device-users";  # TODO: Improve error.
      let
        perDeviceUserAuth = lib.attrsets.mapAttrs (uk: uv:
            let
              rawSelUsers = lib.lists.optionals (uv ? "ssh-users") uv.ssh-users;
              rawSelGroups = lib.lists.optionals (uv ? "ssh-groups") uv.ssh-groups;
              authSrcPathStr = printSrcStrForSrcs authRawAttrs.srcs;
              usersSrcPathStr = printSrcStrForSrcs users.srcs;
              groupsSrcPathStr = printSrcStrForSrcs groups.srcs;

              selSshGroupsBundles = assert builtins.isList rawSelGroups;
                resolveAuthGroupFromSshGroups
                  uk authSrcPathStr groupsSrcPathStr rawSelGroups groups.sshGroups;

              selSshUsersBundle = assert builtins.isList rawSelUsers;
                resolveAuthUsersFromSshUsers
                  uk authSrcPathStr usersSrcPathStr rawSelUsers users.sshUsers;

              effectiveSshUsersBundle = mergeDeviceUserAuthorizedSshGroupsAndUsersAsSshUsersBundle
                mPol.device-user.internal selSshGroupsBundles selSshUsersBundle;
            in
            assert builtins.isList rawSelUsers;
            assert builtins.isList rawSelGroups;
            {
              srcStr = printSrcStrForSrcs authRawAttrs.srcs;
              inherit (effectiveSshUsersBundle) sshUsers;
            }
          )
          authRawAttrs.device-users;
      in {
      inherit (authRawAttrs) srcs;
      deviceUsers = perDeviceUserAuth;
    };


  loadAuthAlwaysRawAttrs = dCfg: dir:
    loadAttrs dCfg.dir-layout.file-format dir dCfg.dir-layout.auth-always defAuthRawAttrs;


  loadAuthAlways' = dCfg: dir: users: groups:
    resolveAuth dCfg.merge-policy users groups (loadAuthAlwaysRawAttrs dCfg dir);


  loadAuthAlways = dCfg: dir:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthAlways' dCfg dir users groups;


  getAuthOnDir = dCfg: dir:
    dir + "/${dCfg.dir-layout.auth-on.dir}";


  listSearchPathsForAuthOn = dCfg: dir: onState:
    mkPathsForSupportedFormats dCfg.dir-layout.file-format dir onState;


  listSearchPathsForAuth = dCfg: dir: onStates:
    lib.lists.concatMap (listSearchPathsForAuthOn dCfg dir) onStates;


  loadAuthOnRawAttrs = dCfg: dir: onState:
    loadAttrs
      dCfg.dir-layout.file-format (getAuthOnDir dCfg dir)
      {stem = onState; mandatory-file = dCfg.dir-layout.auth-on.fail-on-missing-file; } defAuthRawAttrs;


  loadAuthOn' = dCfg: dir: onState: users: groups:
    resolveAuth dCfg.merge-policy users groups (loadAuthOnRawAttrs dCfg dir onState);


  loadAuthOn = dCfg: dir: onState:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthOn' dCfg dir onState users groups;


  loadAuthRawExtra' = dCfg: dir: users: groups: qualifierStr: extraRawAttrs:
    assert null != extraRawAttrs;
    resolveAuth dCfg.merge-policy users groups (
        extendAttrsWSrcsInfo
          dir "in-memory-auth-extra-raw-${qualifierStr}" [] extraRawAttrs
      );


  loadAuthRawExtra = dCfg: dir: qualifierStr: extraRawAttrs:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthRawExtra' dCfg dir users groups qualifierStr extraRawAttrs;


  loadAuthPlain' = dCfg: dir: onStates: users: groups:
      let
        authAlways = loadAuthAlways' dCfg dir users groups;
        listOfPlainAuth =
            [ authAlways ]
         ++ (builtins.map (on: (loadAuthOn' dCfg dir on users groups)) onStates);
      in
    mergeListOfAuthBundles dCfg.merge-policy.device-user.internal listOfPlainAuth;


  loadAuthPlain = dCfg: dir: onStates:
      let
        users = loadUsersPlain dCfg dir;
        groups = loadGroupsPlain' dCfg dir users;
      in
    loadAuthPlain' dCfg dir onStates users groups;


  loadAuthWExtra' = dCfg: dir: onStates: users: groups: {
      extraAuth ? {},
    }:
      let
        plainAuth = loadAuthPlain' dCfg dir onStates users groups;
      in
    mergePlainWExtra
      plainAuth
      extraAuth
      {
        inherited = {
          mergeLOf = mergeListOfAuthBundles dCfg.merge-policy.device-user.inherited;
          loadExtra = loadAuthRawExtra' dCfg dir users groups "inherited";
        };
        override = {
          mergeLOf = mergeListOfAuthBundles dCfg.merge-policy.device-user.override;
          loadExtra = loadAuthRawExtra' dCfg dir users groups "override";
        };
      };


  loadAuthWExtra = dCfg: dir: onStates: {
      extraUsers ? {},
      extraGroups ? {},
      extraAuth ? {},
    }:
      let
        users = loadUsersWExtra dCfg dir { inherit extraUsers; };
        groups = loadGroupsWExtra' dCfg dir users { inherit extraGroups; };
      in
    loadAuthWExtra' dCfg dir onStates users groups { inherit extraAuth; };


  loadAuth = dCfg: dir: onStates:
    loadAuthWExtra dCfg dir onStates {};


  loadAuth' = dCfg: dir: onStates: users: groups:
    loadAuthWExtra' dCfg dir onStates users groups {};
}
