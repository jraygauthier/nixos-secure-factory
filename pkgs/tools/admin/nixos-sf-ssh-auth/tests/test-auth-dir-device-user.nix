{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;

let
  optsEmpty = {};

  optsAllowInexistantDevUsrDef = {
    cfgOverrides.merge-policy.final-device-user.internal.device-user-definition.allow-missing = true;
  };
in

{
  testC1DevRootAuthSshUsersFailsWMissingDef = checkFails
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "root" optsEmpty);
      expected = [];
    };

  testC1DevRootAuthSshUsersWAllowInexDef =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "root" optsAllowInexistantDevUsrDef);
      expected = [];
    };

  testC1DevRootAuthSshPubKeysWAllowInexDef =
    {
      expr =
        listPubKeysContentOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "root" optsAllowInexistantDevUsrDef);
      expected = [];
    };

  testC1DevRootAuthSshUsersWAllowInexDefWForbidEmptyAuthFailsAsExpected = checkFails
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "root"
            {
              cfgOverrides.merge-policy.final-device-user.internal = {
                  device-user-definition.allow-missing = true;
                  authorized-set.forbid-empty-for = ["root"];
                };
            });
      expected = [];
    };

  testC1DevDAuthSshUsersWForbidEmptyAuthFailsAsExpected = checkFails
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "root"
            {
              cfgOverrides.merge-policy.final-device-user.internal = {
                  authorized-set.forbid-empty-for = ["root" "my-device-user-d"];
                };
            });
      expected = [];
    };

  testC1DevUserAAuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "my-device-user-a" optsEmpty);
      expected = [ "my-ssh-user-a" ];
    };

  testC1DevUserAAuthSshPubKeys =
    {
      expr =
        listPubKeysContentOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case1/device-ssh "my-device-user-a" optsEmpty);
      expected = [ "my-ssh-user-a.rsa.pub" ];
    };

  testC2DevRootAuthSshUsersWAllowInexDef =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "root" optsAllowInexistantDevUsrDef);
      expected = [ "my-ssh-user-c" "my-ssh-user-f" ];
    };

  testC2DevRootAuthSshPubKeysWAllowInexDef =
    {
      expr =
        listPubKeysContentOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "root" optsAllowInexistantDevUsrDef);
      expected = [ "my-ssh-user-c.pub" "my-ssh-user-f.pub" ];
    };

  testC2DevUserAAuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-a" optsEmpty);
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" "f" ];
    };

  testC2DevUserAAuthSshPubKeys =
    {
      expr =
        listPubKeysContentOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-a" optsEmpty);
      expected = builtins.map (x: "my-ssh-user-${x}.pub") [ "a" "b" "c" "f" ];
    };

  testC2DevUserBAuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-b" optsEmpty);
      expected = builtins.map (x: "my-ssh-user-${x}") [ "b" "c" "d" "f" ];
    };

  testC2DevUserCAuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-c" optsEmpty);
      expected = builtins.map (x: "my-ssh-user-${x}") [ "c" "e" "f" ];
    };

  testC2DevUserCOnS1AuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-c" {
              onStates = [ "my-state-s1" ];
            }
        );
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" "e" "f" ];
    };

  testC2DevUserCOnS2AuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-c" {
              onStates = [ "my-state-s2" ];
            }
        );
      expected = builtins.map (x: "my-ssh-user-${x}") [ "b" "c" "d" "e" "f" ];
    };

  testC2DevUserCOnS1S3AuthSshUsers =
    {
      expr =
        listNamesOfSshUsersAuthorizedToDeviceUser (
          loadAuthDirDeviceUser ./case2/device-ssh "my-device-user-c" {
              onStates = [ "my-state-s1" "my-state-s3" ];
            }
        );
      expected = builtins.map (x: "my-ssh-user-${x}") [ "a" "b" "c" "d" "e" "f" ];
    };
}