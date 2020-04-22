
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;

  coreModule = callPackage ./nix-lib/core.nix {};
  loaderModule = callPackage ./nix-lib/loader.nix {};
  usersModule = callPackage ./nix-lib/users.nix {};
  groupsModule = callPackage ./nix-lib/groups.nix {};
  authModule = callPackage ./nix-lib/auth.nix {};
  deviceUserModule = callPackage ./nix-lib/device-user.nix {};
  dirModule = callPackage ./nix-lib/dir.nix {};
in

rec {
  inherit
    coreModule
    loaderModule
    usersModule
    groupsModule
    authModule
    deviceUserModule
    dirModule;

  inherit (usersModule)
    listPubKeysForSshUsers
    listPubKeysContentForSshUsers
    listUserNamesForSshUsers;

  inherit (groupsModule)
    listGroupNamesForSshGroups
    listSshUsersMergedFromSshGroups
    listMemberNamesMergedFromSshGroups
    getMembersForSshGroupAsSshUsers
    listMembersNamesForSshGroup
    listMemberPubKeysForSshGroup
    listMemberPubKeysContentForSshGroup;

  # inherit (authModule);

  inherit (deviceUserModule)
    getDeviceUserName
    listNamesOfSshUsersAuthorizedToDeviceUser
    listPubKeysOfSshUsersAuthorizedToDeviceUser
    listPubKeysContentOfSshUsersAuthorizedToDeviceUser;


  inherit (dirModule)
    loadAuthDirPlain
    loadAuthDir
    loadAuthDirWExtra
    loadAuthDirDeviceUser
    loadAuthDirDeviceUserWExtra
    mkAuthDirDeviceUser
    defaultAuthDirCfg
    overrideAuthDirCfg;
}
