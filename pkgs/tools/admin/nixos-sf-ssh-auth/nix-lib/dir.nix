
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
  deviceUserModule = callPackage ./device-user.nix {};
in

with coreModule;
with loaderModule;
with usersModule;
with groupsModule;
with authModule;
with deviceUserModule;

rec {
  # TODO: Change attrs names to use dash instead of camel case. This
  # might get loaded from an external file.
  defaultAuthDirCfg = {
    user-defaults-raw-attr = defUserDefaultsRawAttr;

    dir-layout = {
      file-format = defFileFormats;

      users = {
        stem = "users";
        # If the user file is missing, it is most likely an error.
        mandatory-file = false;
      };

      groups = {
        stem = "groups";
        # Group management is optional.
        mandatory-file = false;
      };

      auth-always = {
        stem = "authorized-always";
        # This is alright to authorize on some state / moments only.
        mandatory-file = false;
      };

      auth-on = {
        dir = "authorized-on";
        # When a particular moment / state is loaded we want it to
        # fail if the file is absent.
        fail-on-missing-file = false;
      };
    };

    merge-policy = rec {
      # Used by `mergeUserAttrSets`.
      # Defaults defined in / validated by `ensureValidUsersMergePolicy`.
      ssh-user.inherited = inheritedUsersMergePolicy;
      ssh-user.override = overrideUsersMergePolicy;

      ssh-group.inherited = inheritedGroupsMergePolicy;
      ssh-group.override = overrideGroupsMergePolicy;

      device-user.internal = internalAuthMergePolicy;
      device-user.inherited = inheritedAuthMergePolicy;
      device-user.override = overrideAuthMergePolicy;

      final-device-user.internal = internalFinalDeviceUserMergePolicy;
    };
  };


  overrideAuthDirCfg =
    overrideAttrs (failOnMissingOrMismatchingTypeAttrOverridePred "authDirCfg");


  mkAuthDirDeviceUser = authDir: deviceUsername:
      let
        deviceUserAuth = mkDeviceUserFromAuth authDir.cfg.merge-policy authDir deviceUsername;
      in
    { inherit authDir; } // deviceUserAuth;


  mkAuthDir' = cfg: onStates: extra: users: groups: auth:
    {
      inherit cfg;
      inherit onStates;
      inherit extra;

      inherit (users) sshUsers;
      inherit (groups) sshGroups;
      inherit (auth) deviceUsers;

      inherit (auth) srcs;
    };


  # Equivalent to `loadAuthDir` but with less merge logic involved
  # as using the `*Plain` variant from each modules.
  # Use instead `loadAuthDir` unless goal is to test lower level code.
  loadAuthDirPlain = dir:
    { cfgBase ? defaultAuthDirCfg
    , cfgOverrides ? {}
    , onStates ? []
    }:
      let
        cfg = overrideAuthDirCfg cfgBase cfgOverrides;
        extra = {};
        users = loadUsersPlain cfg dir;
        groups = loadGroupsPlain' cfg dir users;
        auth = loadAuthPlain' cfg dir onStates users groups;
      in
    mkAuthDir' cfg onStates extra users groups auth;


  loadAuthDir = dir:
    { cfgBase ? defaultAuthDirCfg
    , cfgOverrides ? {}
    , onStates ? []
    }:
      let
        cfg = overrideAuthDirCfg cfgBase cfgOverrides;
        extra = {};
        users = loadUsers cfg dir;
        groups = loadGroups' cfg dir users;
        auth = loadAuth' cfg dir onStates users groups;
      in
    mkAuthDir' cfg onStates extra users groups auth;


  loadAuthDirWExtra = dir:
    { cfgBase ? defaultAuthDirCfg
    , cfgOverrides ? {}
    , onStates ? []
    , extraUsers ? {}
    , extraGroups ? {}
    , extraAuth ? {}
    }:
      let
        cfg = overrideAuthDirCfg cfgBase cfgOverrides;
        extra = {
            users = extraUsers;
            groups = extraGroups;
            auth = extraAuth;
          };
        users = loadUsersWExtra cfg dir { inherit extraUsers; };
        groups = loadGroupsWExtra cfg dir { inherit extraUsers extraGroups; };
        auth = loadAuthWExtra cfg dir onStates { inherit extraUsers extraGroups extraAuth; };
      in
    mkAuthDir' cfg onStates extra users groups auth;


  loadAuthDirDeviceUser = dir: deviceUsername: opts:
    mkAuthDirDeviceUser (loadAuthDir dir opts) deviceUsername;


  loadAuthDirDeviceUserWExtra = dir: deviceUsername: opts:
    mkAuthDirDeviceUser (loadAuthDirWExtra dir opts) deviceUsername;
}
