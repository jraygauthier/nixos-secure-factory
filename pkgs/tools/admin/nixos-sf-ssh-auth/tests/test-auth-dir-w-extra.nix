{ testTools
, sshAuthLib
, symlinkJoin
, writeTextDir
, writeText
}:

with testTools;
with sshAuthLib;

let
  adC3F = loadAuthDir ./case3/device-ssh-f {};
  adC3C = loadAuthDir ./case3/device-ssh-c {};
  adC3D = loadAuthDir ./case3/device-ssh-d {};

  rawF1F2UsersMissingPubKeys =
    {
      ssh-users = {
        my-ssh-user-f1 = {};
        my-ssh-user-f2 = {};
      };
    };

  rawF1F2UsersPubkeyDir = symlinkJoin
    {
      name = "raw-f1-f2-public-keys";
      paths =
        [
          (writeTextDir "my-ssh-user-f1.pub" "raw/my-ssh-user-f1.pub")
          (writeTextDir "my-ssh-user-f2.pub" "raw/my-ssh-user-f2.pub")
        ];
    };

  rawF1F2Users = rawF1F2UsersMissingPubKeys // {
    ssh-user-defaults.pubkey-file-search-path = [
      rawF1F2UsersPubkeyDir
    ];
  };

  rawC2C3Users = {
    ssh-users = {
      my-ssh-user-c2 = {
        pubkey-file = writeText "id_rsa" "raw/my-ssh-user-c2.pub";
      };
      my-ssh-user-c3 = {
        pubkey-file = writeText "id_rsa" "raw/my-ssh-user-c3.pub";
      };
    };
  };

  rawF1F2C2C3Users = {
    inherit (rawF1F2Users) ssh-user-defaults;
    ssh-users = rawF1F2Users.ssh-users // rawC2C3Users.ssh-users;
  };

  rawCAdminGroups = {
    ssh-groups.my-group-c-admin.members = [
      "my-ssh-user-c1"
      "my-ssh-user-c2"
    ];
  };

  rawCDevGroups = {
    ssh-groups.my-group-c-dev.members = [
      "my-ssh-user-f1"
      "my-ssh-user-f2"
    ];
  };

  rawCAdminCDevGroups = {
    ssh-groups = rawCAdminGroups.ssh-groups // rawCDevGroups.ssh-groups;
  };

  rawCNewGroups = {
    ssh-groups.my-group-c-new.members = [
      "my-ssh-user-f1"
      "my-ssh-user-f2"
    ];
  };
in

{
  testLoadAuthDirListUsersC3F =
    {
      expr = listUserNamesForSshUsers adC3F;
      expected = map (x: "my-ssh-user-${x}") ["f1" "f2" "f3"];
    };

  testLoadAuthDirListUsersC3C =
    {
      expr = listUserNamesForSshUsers adC3C;
      expected = map (x: "my-ssh-user-${x}") ["c0" "c1" "c2" "c3"];
    };

  testLoadAuthDirListUsersC3D =
    {
      expr = listUserNamesForSshUsers adC3D;
      expected = map (x: "my-ssh-user-${x}") ["d1" "d2"];
    };

  testLoadAuthDirListUsersC3CWInheritedRawExtra =
    {
      expr = listUserNamesForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawInherited = rawF1F2UsersMissingPubKeys;});
      expected = map (x: "my-ssh-user-${x}") ["c0" "c1" "c2" "c3" "f1" "f2"];
    };

  testLoadAuthDirListPubKeysC3CWInheritedRawExtraErrorAsMissingPubKeys = checkFails
    {
      expr = listPubKeysContentForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawInherited = rawF1F2UsersMissingPubKeys;});
    };

  testLoadAuthDirListPubKeysC3CWInheritedRawExtra =
    {
      expr = listPubKeysContentForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawInherited = rawF1F2Users;});
      expected = map (x: "c/.+/my-ssh-user-${x}.pub") ["c0" "c1" "c2" "c3" ] ++ map (x: "raw/my-ssh-user-${x}.pub") ["f1" "f2"];
    };

  testLoadAuthDirListPubKeysC3CWInheritedRawExtraWOverlap =
    {
      expr = listPubKeysContentForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawInherited = rawC2C3Users;});
      expected = map (x: "c/.+/my-ssh-user-${x}.pub") ["c0" "c1" "c2" "c3" ];
    };

  testLoadAuthDirListUsersC3CWOverrideRawExtraWOverlap =
    {
      expr = listUserNamesForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawOverride = rawC2C3Users;});
      expected = map (x: "my-ssh-user-${x}") ["c0" "c1" "c2" "c3"];
    };

  testLoadAuthDirListPubKeysC3CWOverrideRawExtraWOverlap =
    {
      expr = listPubKeysContentForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.rawOverride = rawC2C3Users;});
      expected = map (x: "c/.+/my-ssh-user-${x}.pub") ["c0" "c1" ] ++ map (x: "raw/my-ssh-user-${x}.pub") ["c2" "c3" ];
    };

  testLoadAuthDirListUsersWExtraInheritUsers =
    {
      expr = listUserNamesForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c { extraUsers.inherited = adC3F; });
      expected = map (x: "my-ssh-user-${x}") ["c0" "c1" "c2" "c3" "f1" "f2" "f3"];
    };

  testLoadAuthDirListUsersWExtraInheritAndOverrideUsers =
    {
      expr = listUserNamesForSshUsers (loadAuthDirWExtra ./case3/device-ssh-c {
        extraUsers.inherited = adC3F; extraUsers.override = adC3D; });
      expected = map (x: "my-ssh-user-${x}") ["c0" "c1" "c2" "c3" "d1" "d2" "f1" "f2" "f3"];
    };

  testLoadAuthDirListGroupsWExtraInheritGroupsRawWOverlap =
      let
        ad = loadAuthDirWExtra ./case3/device-ssh-c
          {
            extraGroups.rawInherited = rawCAdminGroups;
            extraUsers.rawOverride = rawC2C3Users;
          };
      in
    {
      expr =
        {
          groupNames = listGroupNamesForSshGroups ad;
          cAdminGroupMemberNames = listMembersNamesForSshGroup "my-group-c-admin" ad;
          cAdminGroupMemberPubKeys = listMemberPubKeysContentForSshGroup "my-group-c-admin" ad;
        };
      expected =
        {
          groupNames = map (x: "my-group-${x}") ["c-admin" "c-dev" "c-support"];
          # We can see that by default (without piecewise merge), an inherited group cannot
          # inject its members in an existing group. See below test for the piecewise merge option.
          cAdminGroupMemberNames = map (x: "my-ssh-user-${x}") [ "c0" ];
          # We can see here that the users added as extra override are indeed effecive in the inherited group.
          cAdminGroupMemberPubKeys = map (x: "c/.+/my-ssh-user-${x}.pub") [ "c0" ];
        };
    };

  testLoadAuthDirListGroupsWExtraInheritGroupsRawWOverlapWPiecewiseMerge =
    let
      ad = loadAuthDirWExtra ./case3/device-ssh-c
        {
          extraGroups.rawInherited = rawCAdminGroups;
          extraUsers.rawOverride = rawC2C3Users;
          cfgOverrides.merge-policy.ssh-group.inherited.member-set.merge-mismatching = {
              allow = true;
              method = "piecewise-mix";
            };
        };
    in
    {
      expr =
        {
          groupNames = listGroupNamesForSshGroups ad;
          cAdminGroupMemberNames = listMembersNamesForSshGroup "my-group-c-admin" ad;
          cAdminGroupMemberPubKeys = listMemberPubKeysContentForSshGroup "my-group-c-admin" ad;
        };
      expected =
        {
          groupNames = map (x: "my-group-${x}") ["c-admin" "c-dev" "c-support"];
          # We can see that with the piecewise merge switch on, inherited groups members are included
          # into our memberset.
          cAdminGroupMemberNames = map (x: "my-ssh-user-${x}") [ "c0" "c1" "c2"];
          # We can see here that the users added as extra override are indeed effecive in the inherited group.
          cAdminGroupMemberPubKeys = map (x: "c/.+/my-ssh-user-${x}.pub") [ "c0" "c1"] ++ ["raw/my-ssh-user-c2.pub"];
        };
    };

  testLoadAuthDirListGroupsWExtraInheritGroupsRawNoOverlap =
      let
        ad = loadAuthDirWExtra ./case3/device-ssh-c
          {
            extraGroups.rawInherited = rawCNewGroups;
            extraUsers.rawOverride = rawF1F2Users;
          };
      in
    {
      expr =
        {
          groupNames = listGroupNamesForSshGroups ad;
          cNewGroupMemberNames = listMembersNamesForSshGroup "my-group-c-new" ad;
          cNewGroupMemberPubKeys = listMemberPubKeysContentForSshGroup "my-group-c-new" ad;
        };
      expected =
        {
          groupNames = map (x: "my-group-${x}") ["c-admin" "c-dev" "c-new" "c-support" ];
          cNewGroupMemberNames = map (x: "my-ssh-user-${x}") [ "f1" "f2" ];
          cNewGroupMemberPubKeys = map (x: "raw/my-ssh-user-${x}.pub") [ "f1" "f2" ];
        };
    };

  testLoadAuthDirListGroupsWExtraInheritGroups =
      let
        ad = loadAuthDirWExtra ./case3/device-ssh-c {
            extraGroups.inherited = adC3F;
          };
      in
    {
      expr.groupNames = listGroupNamesForSshGroups ad;
      expected.groupNames = map (x: "my-group-${x}") ["c-admin" "c-dev" "c-support" "f1"];
    };

  testLoadAuthDirListGroupsWExtraInheritAndOverrideGroups =
      let
        ad = loadAuthDirWExtra ./case3/device-ssh-c {
            extraGroups.inherited = adC3F;
            extraGroups.override = adC3D;
          };
      in
    {
      expr.groupNames = listGroupNamesForSshGroups (loadAuthDirWExtra ./case3/device-ssh-c
        {
          extraGroups.inherited = adC3F;
          extraGroups.override = adC3D;
        });
      expected.groupNames = map (x: "my-group-${x}") ["1" "2" "3" "c-admin" "c-dev" "c-support" "f1"];
    };
}