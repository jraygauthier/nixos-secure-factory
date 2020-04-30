
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  coreModule = callPackage ./core.nix {};
  loaderModule = callPackage ./loader.nix {};
  usersModule = callPackage ./users.nix {};
in

with coreModule;
with loaderModule;
with usersModule;

rec {
  defGroupsRawAttrs = {
    ssh-groups = {};
  };


  loadGroupsRawAttrs = dCfg: dir:
    loadAttrs dCfg.dir-layout.file-format dir dCfg.dir-layout.groups defGroupsRawAttrs;


  isSshGroups = groups:
    groups ? "sshGroups";


  isSshGroupsValue = groupValue:
    groupValue ? "members";


  mkSshGroups = groupsAttrSet: {
      sshGroups = lib.attrsets.mapAttrs (k: v:
          assert isSshGroupsValue v;
          v
        )
        groupsAttrSet;
    };


  listGroupNamesForSshGroups = groups:
    assert isSshGroups groups;
    lib.attrsets.mapAttrsToList (k: v: k) groups.sshGroups;


  mkSshGroupnamesForSshGroups = groups: {
      sshGroupnames = listGroupNamesForSshGroups users;
    };


  listSshUsersMergedFromSshGroups = groups:
    _mergeMembersFromGroupsAsSshUsers groups;


  listMemberNamesMergedFromSshGroups = groups:
    lib.attrsets.mapAttrsToList (k: _: k) (listSshUsersMergedFromSshGroups groups).sshUsers;


  getMembersForSshGroupAsSshUsers = groupName: groups:
    # TODO: Improve error message and centralize.
    assert groups.sshGroups ? "${groupName}";
    mkSshUsers groups.sshGroups."${groupName}".members;


  listMembersNamesForSshGroup = groupName: groups:
    listUserNamesForSshUsers (getMembersForSshGroupAsSshUsers groupName groups);


  listMemberPubKeysForSshGroup = groupName: groups:
    listPubKeysForSshUsers (getMembersForSshGroupAsSshUsers groupName groups);


  listMemberPubKeysContentForSshGroup = groupName: groups:
    listPubKeysContentForSshUsers (getMembersForSshGroupAsSshUsers groupName groups);


  validMergeMismatchingMemberSetMethodFieldValues =
    [
      "whole-override"
      "piecewise-mix"
    ];


  validMergeMismatchingMemberSetMethodFieldValuesWDefault =
    ["default"] ++ validMergeMismatchingMemberSetMethodFieldValues;


  ensureValidMPolMergeMismatchingMemberSetCfg = {
        # When disabled, an error will be raised when mismatching groups are found.
        allow ? false,
        method ? "default"  # Is 'whole-override'.
        # 'whole-override':
        #   Lhs memberset will be completly overriden by rhs memberset.
        #   (e.g: rhs will preserve its integrity, nothing from lhs will
        #   be injected into rhs).
        # 'piecewise-mix':
        #   Lhs memberset will be mixed with rhs according to specified
        #   `ssh-user` policy (which by default favor rhs override of lhs pubkey
        #   for members with same names).
        #   WARNING: Lhs members will be injected into rhs memberse which
        #   will change the original definition of the group which most
        #   likely will get expanded to authorize its ssh users to device user.
        #   Thus, lhs **must** be highly trusted as an attacker might obtain
        #   priviledges this way.
        #   This is the reason why this is off be default.
      }:
      let
        resolvedDefaultValue = "whole-override";
        validMethods = validMergeMismatchingMemberSetMethodFieldValuesWDefault;
        methodIsValid = lib.lists.elem method validMethods;
        validMethodsStr = lib.strings.concatStringsSep "\n" validMethods;
      in
    assert lib.asserts.assertMsg (methodIsValid)
      ( "Invalid \"member-set.merge-mismatching.method\" field value. "
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


  defMPolMergeMismatchingMemberSetCfg = ensureValidMPolMergeMismatchingMemberSetCfg {};


  ensureValidMPolGroupMemberSetCfg = {
        merge-mismatching ? defMPolMergeMismatchingMemberSetCfg
      }:
    {
      merge-mismatching = ensureValidMPolMergeMismatchingMemberSetCfg merge-mismatching;
    };


  defMPolGroupMemberSetCfg = ensureValidMPolGroupMemberSetCfg {};


  ensureValidGroupsMergePolicy = {
        # How to merge ssh users when merging 2 groups.
        ssh-user ? defUsersMergePolicy,
        member-set ? defMPolGroupMemberSetCfg
      }:
    {
      ssh-user = ensureValidUsersMergePolicy ssh-user;
      member-set = ensureValidMPolGroupMemberSetCfg member-set;
    };


  defGroupsMergePolicy = ensureValidGroupsMergePolicy {};


  inheritedGroupsMergePolicy = ensureValidGroupsMergePolicy {
      ssh-user = inheritedUsersMergePolicy;
      # See `ensureValidGroupsMergePolicy` comment before changing the below
      # value. This can be a security concern if lightly changed to
      # something else.
      member-set.merge-mismatching.allow = true;
    };


  overrideGroupsMergePolicy = ensureValidGroupsMergePolicy {
      ssh-user = overrideUsersMergePolicy;
      # See `ensureValidGroupsMergePolicy` comment before changing the below
      # value. This can be a security concern if lightly changed to
      # something else.
      member-set.merge-mismatching.allow = true;
    };


  # See `ensureValidGroupsMergePolicy` comment for security implication
  # of using this policy.
  inheritedGroupsMergePolicyWPiecewise = inheritedGroupsMergePolicy // {
      member-set.merge-mismatching = {
          allow = true;
          method = "piecewise-mix";
        };
    };


  # See `ensureValidGroupsMergePolicy` comment for security implication
  # of using this policy.
  overrideGroupsMergePolicyWPiecewise = overrideGroupsMergePolicy // {
      member-set.merge-mismatching = {
          allow = true;
          method = "piecewise-mix";
        };
    };


  defOnDisallowedMergeMismatchingMemberSetMsg = gName: xg: yg:
      "Merge policy does not allow us to merge group '${gName}' from '${xg.srcStr}' with group '${gName}' from '${yg.srcStr}'. "
    + "Those groups have mismatching members: ''\n${printAttrsetKeysDiffStr xg.members yg.members}\n''";


  defGroupsMergeOpts = {};


  mergeSameNameGroups = gmPol: {
        onDisallowedMergeMismatchingMemberSetMsg ? defOnDisallowedMergeMismatchingMemberSetMsg
      }: gName: xg: yg:
    assert isSshGroupsValue xg;
    assert isSshGroupsValue yg;
      let
        gmPolValid = ensureValidGroupsMergePolicy gmPol;
        sameMemKs = attrsetSameKeys xg.members yg.members;
        allowMergeMismatching = gmPolValid.member-set.merge-mismatching.allow;
      in
    assert lib.asserts.assertMsg (allowMergeMismatching || sameMemKs) (
        onDisallowedMergeMismatchingMemberSetMsg gName xg yg
      );

    if sameMemKs
      then
        # Lhs does not bring anything new to the table so rhs's memberset is taken as a whole
        # diregarding lhs.
        yg
    else if "piecewise-mix" == gmPolValid.member-set.merge-mismatching.method
      then
        {
          # Some part of lhs's memberset is allowed to be injected into rhs according to
          # current `ssh-user` policy (by default a rhs user will override the lhs user as a whole).
          # See `ensureValidGroupsMergePolicy` important comment about this option's security.
          # TODO: Specialize `defUsersMergeOpts` in order to improve error messages.
          members = mergeUserAttrSets gmPolValid.ssh-user defUsersMergeOpts xg.members yg.members;
          srcStr = mergeSrcStrList [xg.srcStr yg.srcStr];
        }
    else
      assert "whole-override" == gmPolValid.member-set.merge-mismatching.method;
      # Rhs's memberset is chosen as a whole.
      yg;



  mergeSameNameGroupList = gmPol: opts: gName: gValues:
    assert 1 <= lib.lists.length gValues;
    lib.lists.foldl' (mergeSameNameGroups gmPol opts gName) (lib.lists.head gValues) (lib.lists.tail gValues);


  mergeGroupAttrSets = gmPol: opts: gSetA: gSetB:
      assert builtins.isAttrs gSetA;
      assert builtins.isAttrs gSetB;
    # Remember that rightmost has priority over leftmost when same key.
    lib.attrsets.zipAttrsWith (mergeSameNameGroupList gmPol opts) [ gSetA gSetB ];


  mergeListOfGroupAttrSets = gmPol: xs:
    lib.lists.foldl' (mergeGroupAttrSets gmPol defGroupsMergeOpts) {} xs;


  mergeListOfGroupBundles = gmPol: xs: {
      srcs = lib.lists.concatLists (builtins.map (x: x.srcs) xs);
      sshGroups = mergeListOfGroupAttrSets gmPol (builtins.map (x: x.sshGroups) xs);
    };


  _mergeMembersFromGroupsAsSshUsers = groups:
    assert isSshGroups groups; {
      # TODO: Specialize `defUsersMergeOpts` for group expansion in order to
      # improve error message.
      sshUsers = mergeListOfUserAttrSets defUsersMergePolicy defUsersMergeOpts (
        lib.attrsets.mapAttrsToList (k: v:
            v.members
          )
          groups.sshGroups
        );
    };


  resolveRawGroupMembersFromSshUsers = groupName: groupSrcFile: usersSrcFile:
    cherryPickFromAttrs (onGenMissingAttr "group" groupName groupSrcFile "user group member" "users attrset" usersSrcFile);


  resolveGroups = users: groupsRawAttrs:
      assert groupsRawAttrs ? "ssh-groups"; # TODO: Improve error.
      let
        groups = lib.attrsets.mapAttrs (uk: uv:
            let
              rawMembers = uv.members;
              groupsSrcPathStr = printSrcStrForSrcs groupsRawAttrs.srcs;
              usersSrcPathStr = printSrcStrForSrcs users.srcs;
            in
            assert uv ? "members"; # TODO: Improve error.
            assert builtins.isList rawMembers; {
              members = resolveRawGroupMembersFromSshUsers
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


  loadGroupsPlain' = dCfg: dir: users:
      let
        rawAttrs = loadGroupsRawAttrs dCfg dir;
      in
    resolveGroups users rawAttrs;


  loadGroupsPlain = dCfg: dir:
      let
        users = loadUsersPlain dCfg dir;
      in
    loadGroupsPlain' dCfg dir users;


  loadGroupsRawExtra' = dCfg: dir: users: qualifierStr: extraRawAttrs:
    assert null != extraRawAttrs;
      let
        rawAttrs = extendAttrsWSrcsInfo
          dir "in-memory-group-extra-raw-${qualifierStr}" [] extraRawAttrs;
      in
    resolveGroups users rawAttrs;


  loadGroupsRawExtra = dCfg: dir: qualifierStr: extraRawAttrs:
    loadGroupsRawExtra'
      dCfg dir (loadUsersPlain dCfg dir)
      qualifierStr extraRawAttrs;


  loadGroupsWExtra' = dCfg: dir: users: {
      extraGroups ? {}
    }:
    mergePlainWExtra
      (loadGroupsPlain' dCfg dir users)
      extraGroups
      {
        inherited = {
          mergeLOf = mergeListOfGroupBundles dCfg.merge-policy.ssh-group.inherited;
          loadExtra = loadGroupsRawExtra' dCfg dir users "inherited";
        };
        override = {
          mergeLOf = mergeListOfGroupBundles dCfg.merge-policy.ssh-group.override;
          loadExtra = loadGroupsRawExtra' dCfg dir users "override";
        };
      };


  loadGroupsWExtra = dCfg: dir: {
      extraUsers ? {},
      extraGroups ? {}
    }:
      let
        users = loadUsersWExtra dCfg dir { inherit extraUsers; };
      in
    loadGroupsWExtra' dCfg dir users {inherit extraGroups; };


  loadGroups' = dCfg: dir: users:
    loadGroupsWExtra' dCfg dir users {};


  loadGroups = dCfg: dir:
    loadGroupsWExtra dCfg dir {};
}
