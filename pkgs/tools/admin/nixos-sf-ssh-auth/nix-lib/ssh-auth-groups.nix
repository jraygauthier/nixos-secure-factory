
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  sshAuthLoader = callPackage ./ssh-auth-loader.nix {};
  sshAuthUsers = callPackage ./ssh-auth-users.nix {};
in

with sshAuthLoader;
with sshAuthUsers;

rec {
  defGroupsRawAttrs = {
    ssh-groups = {};
  };


  loadGroupsRawAttrs = dCfg: dir:
    loadAttrs dCfg.dirLayout.fileFormat dir dCfg.dirLayout.groups defGroupsRawAttrs;


  onGenMissingAttr = ctxQualifier: ctxName: ctxPath: keyQualifierStr: attrsetQualifier: attrSetPath: ak: aset:
      let
        availUsersStr = lib.strings.concatStringsSep "\n" (lib.attrsets.attrNames aset);
      in
    assert lib.asserts.assertMsg false
      ( "Cannot expand \"${keyQualifierStr}\" '${ak}' from \"${ctxQualifier}\" '${ctxName}' defined in '${builtins.toString ctxPath}'.\n"
      + "This is because we cannot find '${ak}' in \"${attrsetQualifier}\" defined at '${builtins.toString attrSetPath}'.\n"
      + "A valid \"${keyQualifierStr}\" should be one of the following: ''\n${availUsersStr}\n''."
      );
    null;


  selectFromAttrs = onMissingAttr: selectedKeys: attrset:
    lib.attrsets.genAttrs selectedKeys (ak:
        lib.attrsets.attrByPath [ ak ] (onMissingAttr ak attrset) attrset
      );


  selectFromUserGroupMemberAttrs = groupName: groupSrcFile: usersSrcFile:
    selectFromAttrs (onGenMissingAttr "group" groupName groupSrcFile "user group member" "users attrset" usersSrcFile);

  selectFromDeviceAuthUserAttrs = deviceUserName: authSrcFile: usersSrcFile:
    selectFromAttrs (onGenMissingAttr "device user" deviceUserName authSrcFile "authorized user" "user attrset" usersSrcFile);

  selectFromDeviceAuthGroupAttrs = deviceUserName: authSrcFile: groupsSrcFile:
    selectFromAttrs (onGenMissingAttr "device user" deviceUserName authSrcFile "authorized group" "group attrset" groupsSrcFile);


  resolveGroups = users: groupsRawAttrs:
      assert groupsRawAttrs ? "ssh-groups"; # TODO: Improve error.
      let
        groups = lib.attrsets.mapAttrs (uk: uv:
            let
              rawMembers = uv.members;
              groupsSrcPathStr = printSrcPaths groupsRawAttrs.srcs;
              usersSrcPathStr = printSrcPaths users.srcs;
            in
            assert uv ? "members"; # TODO: Improve error.
            assert builtins.isList rawMembers; {
              members = selectFromUserGroupMemberAttrs
                uk groupsSrcPathStr usersSrcPathStr rawMembers users.sshUsers;

              # This is only used to improve errors messages. Not concrete use yet.
              srcStr = groupsSrcPathStr;
            }
          )
          groupsRawAttrs.ssh-groups;
      in {
      inherit (groupsRawAttrs) srcs;
      sshGroups = groups;
    };


  loadGroups' = dCfg: dir: users:
    resolveGroups users (loadGroupsRawAttrs dCfg dir);


  loadGroups = dCfg: dir:
    loadGroups' dCfg dir (loadUsers dCfg dir);


  defAuthRawAttrs = {
    device-users = {};
  };
}
