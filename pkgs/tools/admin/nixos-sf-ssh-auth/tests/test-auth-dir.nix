{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;

{
  testC1AllUsersNames =
    {
      expr = listUserNamesForSshUsers (loadAuthDir ./case1/device-ssh {});
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" "d" "e" "f" "g" ];
    };

  testC1AllUsersKeys =
    {
      expr = listPubKeysContentForSshUsers (loadAuthDir ./case1/device-ssh {});
      expected =
          builtins.map (x: "my-ssh-user-${x}.pub") [ "a.rsa" "b" "c.ed25519" "d.ed25519" "e" ]
       ++ [ "inherited/my-ssh-user-f.pub" "override/my-ssh-user-g.pub" ];
    };

  testC2AllUsersNames =
    {
      expr = listUserNamesForSshUsers (loadAuthDir ./case2/device-ssh {});
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" "d" "e" "f" ];
    };

  testC2AllGroupsNames =
    {
      expr = listGroupNamesForSshGroups (loadAuthDir ./case2/device-ssh {});
      expected = builtins.map (x: "my-group-${x}") [ "1" "2" "3" ];
    };

  testC2MemberNamesMergedFromAllGroups =
    {
      expr = listMemberNamesMergedFromSshGroups (loadAuthDir ./case2/device-ssh {});
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" ];
    };
}
