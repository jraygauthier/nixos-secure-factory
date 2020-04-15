
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  sshAuthLoader = callPackage ./ssh-auth-loader.nix {};
  sshAuthUsers = callPackage ./ssh-auth-users.nix {};
  sshAuthGroups = callPackage ./ssh-auth-groups.nix {};
in

with sshAuthLoader;
with sshAuthUsers;
with sshAuthGroups;

rec {
  defaultAuthDirCfg = {
    userDefaultsRawAttr = {
      pubkey-file-template = [
        "\${ssh-user.name}.pub"
      ];
      pubkey-file-search-path = [
        "./public-keys"
      ];
    };

    dirLayout = {
      fileFormat = [
        { ext = "nix"; }
        { ext = "json"; }
        # Yaml support needs more work. Do not activate by default.
        # { ext = "yaml"; }
      ];

      users = {
        stem = "users";
        # If the user file is missing, it is most likely an error.
        mandatoryFile = true;
      };

      groups = {
        stem = "groups";
        # Group management is optional.
        mandatoryFile = false;
      };

      authAlways = {
        stem = "authorized-always";
        # This is alright to authorize on some state / moments only.
        mandatoryFile = false;
      };

      authOn = {
        dir = "authorized-on";
        # When a particular moment / state is loaded we want it to
        # fail if the file is absent.
        failOnMissingFile = true;
      };
    };

    mergePolicy = {
      user = {
        allowSilentMergeMismatchingPubKeys = false;
      };
    };
  };


  defAuthRawAttrs = {
    device-users = {};
  };


  mergeListOfDeviceUserAuthorizedSshUsers = mPol: xs:
    mergeListOfUsers mPol xs;


  mergeListOfAuth = mPol: xs: {
    srcs = lib.lists.concatLists (builtins.map (x: x.srcs) xs);
    deviceUsers =
      lib.attrsets.zipAttrsWith (k: vs: mergeListOfDeviceUserAuthorizedSshUsers mPol vs)
        (builtins.map (x: x.deviceUsers) xs);
  };


  resolveAuth = mPol: users: groups: authRawAttrs:
      assert authRawAttrs ? "device-users";  # TODO: Improve error.
      let
        srcs = lib.lists.concatLists (builtins.map (x: x.srcs) [
            authRawAttrs
            # TODO: We can decide here to only include the sources files
            # required to expanded listed users and groups, and this, on
            # a per device user fashion.
            groups users
          ]);

        perDeviceUserAuth = lib.attrsets.mapAttrs (uk: uv:
            let
              rawSelUsers = lib.lists.optionals (uv ? "ssh-users") uv.ssh-users;
              rawSelGroups = lib.lists.optionals (uv ? "ssh-groups") uv.ssh-groups;
              authSrcPathStr = printSrcPaths authRawAttrs.srcs;
              usersSrcPathStr = printSrcPaths users.srcs;
              groupsSrcPathStr = printSrcPaths groups.srcs;

              selUsers = assert builtins.isList rawSelUsers;
                selectFromDeviceAuthUserAttrs
                  uk authSrcPathStr usersSrcPathStr rawSelUsers users.sshUsers;
              selGroups = assert builtins.isList rawSelGroups;
                selectFromDeviceAuthGroupAttrs
                  uk authSrcPathStr groupsSrcPathStr rawSelGroups groups.sshGroups;

              sshUsers = mergeListOfUsersAttrs mPol (
                  lib.attrsets.mapAttrsToList (k: v: v.members) selGroups ++ [ selUsers ]
                );
            in
            assert builtins.isList rawSelUsers;
            assert builtins.isList rawSelGroups;
            {
              inherit srcs;
              inherit sshUsers;
            }
          )
          authRawAttrs.device-users;
      in {
      inherit srcs;
      deviceUsers = perDeviceUserAuth;
    };


  loadAuthAlwaysRawAttrs = dCfg: dir:
    loadAttrs dCfg.dirLayout.fileFormat dir dCfg.dirLayout.authAlways defAuthRawAttrs;


  loadAuthAlways' = dCfg: dir: users: groups:
    resolveAuth dCfg.mergePolicy users groups (loadAuthAlwaysRawAttrs dCfg dir);


  loadAuthAlways = dCfg: dir:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthAlways' dCfg dir users groups;


  getAuthOnDir = dCfg: dir:
    dir + "/${dCfg.dirLayout.authOn.dir}";


  loadAuthOnRawAttrs = dCfg: dir: onState:
    loadAttrs
      dCfg.dirLayout.fileFormat (getAuthOnDir dCfg dir)
      {stem = onState; mandatoryFile = dCfg.dirLayout.authOn.failOnMissingFile; } defAuthRawAttrs;


  loadAuthOn' = dCfg: dir: onState: users: groups:
    resolveAuth dCfg.mergePolicy users groups (loadAuthOnRawAttrs dCfg dir onState);


  loadAuthOn = dCfg: dir: onState:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthOn' dCfg dir onState users groups;


  loadAuthExtra' = dCfg: dir: users: groups: qualifierStr: extraRawAttrs:
    assert null != extraRawAttrs;
    resolveAuth dCfg.mergePolicy users groups (
        extendAttrsWSrcsInfo
          dir "in-memory-auth-extra-${qualifierStr}" [] extraRawAttrs
      );


  loadAuthExtra = dCfg: dir: qualifierStr: extraRawAttrs:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
      in
    loadAuthExtra' dCfg dir users groups qualifierStr extraRawAttrs;


  loadAuthWExtra = dCfg: dir: onStates: {
      extraUsersInherited ? null,
      extraUsersOverride ? null,
      extraAuthInherited ? null,
      extraAuthOverride ? null
    }:
      let
        users = loadUsers dCfg dir;
        groups = loadGroups' dCfg dir users;
        authAlways = loadAuthAlways' dCfg dir users groups;
        deviceUsers = mergeListOfAuth dCfg.mergePolicy (
              lib.lists.optional (null != extraAuthInherited) (
                loadAuthExtra' dCfg dir users groups "inherited" extraAuthInherited
              )
          ++  builtins.map (on: (loadAuthOn' dCfg dir on users groups)) onStates
          ++  [ authAlways ]
          ++  lib.lists.optional (null != extraAuthOverride) (
                loadAuthExtra' dCfg dir users groups "override" extraAuthOverride
              )
          );
      in
    deviceUsers;


  loadAuth = dCfg: dir: onStates:
    loadAuthWExtra dCfg dir onStates {};


  getDeviceUserAuth = mPol: auth: deviceUsername:
      let dus = auth.deviceUsers; in
    assert lib.asserts.assertMsg ("" != deviceUsername)
      "Invalid device username: '${deviceUsername}'.";
    mergeListOfDeviceUserAuthorizedSshUsers mPol ([]
      ++ lib.lists.optional (dus ? "") dus.""
      ++ lib.lists.optional ("" != deviceUsername && dus ? "${deviceUsername}") dus."${deviceUsername}"
      );


  getDeviceUserAuthSshPubKeys = mPol: auth: deviceUsername:
      let
        duAuth = getDeviceUserAuth mPol auth deviceUsername;
        sshPubKeys = lib.attrsets.mapAttrsToList (k: v: v.pubkey.file) duAuth.sshUsers;
      in {
        inherit sshPubKeys;
    };


  loadAuthSshPubKeysForDeviceUser = dCfg: dir: onStates: deviceUsername:
      let
        auth = loadAuth dCfg dir onStates;
        sshPubKeys = getDeviceUserAuthSshPubKeys dCfg.mergePolicy auth deviceUsername;
      in
    sshPubKeys;


  mkAuthDirModule = dir:
    { dirCfg ? defaultAuthDirCfg
    , onStates ? []
    }:
  {
    getDirCfg = dirCfg;
    getOnStates = onStates;

    loadUsers = loadUsers dirCfg dir;
    loadUsersExtra = loadUsersExtra dirCfg dir;
    loadUsersWExtra = loadUsersWExtra dirCfg dir;

    loadGroups = loadGroups dirCfg dir;

    loadAuthAlways = loadAuthAlways dirCfg dir;
    loadAuthOn = onState: loadAuthOn dirCfg dir onState;
    loadAuth = loadAuth dirCfg dir onStates;
    loadAuthExtra = loadAuthExtra dirCfg dir;
    loadAuthWExtra = loadAuthWExtra dirCfg dir onStates;

    loadAuthSshPubKeysForDeviceUser =
      loadAuthSshPubKeysForDeviceUser dirCfg dir onStates;
  };
}
