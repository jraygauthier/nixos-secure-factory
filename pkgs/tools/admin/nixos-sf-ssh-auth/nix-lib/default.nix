
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
  dirModule = callPackage ./dir.nix {};
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
