{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;

let
  mPolOvAllowInexistantDevUsrDef = {
    final-device-user.internal.device-user-definition.allow-missing = true;
  };

  cfgOvAllowInexistantDevUsrDef = {
    merge-policy = mPolOvAllowInexistantDevUsrDef;
  };

  optsAllowInexistantDevUsrDef = {
    cfgOverrides = cfgOvAllowInexistantDevUsrDef;
  };

  adC3F = loadAuthDir ./case3/device-ssh-f {};
  adC3FOnFactoryInstall = loadAuthDir ./case3/device-ssh-f { onStates = [ "my-state-factory-install" ]; };
  adC3C = loadAuthDir ./case3/device-ssh-c {};
  adC3D = loadAuthDirWExtra ./case3/device-ssh-d
    {
      extraUsers.inherited = adC3C;
      extraGroups.inherited = adC3C;
    };
  adC3DOnFactoryInstall = loadAuthDirWExtra ./case3/device-ssh-d
    {
      extraUsers.inherited = adC3C;
      extraGroups.inherited = adC3C;
      onStates = [ "my-state-factory-install" ];
    };

in

{
  testLoadAuthDirDeviceUserAllDevUsersAuthWAllowInexDef =
    {
      expr = listNamesOfSshUsersAuthorizedToDeviceUser (
        loadAuthDirDeviceUser ./case3/device-ssh-c "root" optsAllowInexistantDevUsrDef);
      expected = [ "my-ssh-user-c0" ];
    };

  testLoadAuthDirDeviceUserWExtraInheritedStatesLimitedToLocalDirWAllowInexDef =
      let
        ad = loadAuthDirDeviceUserWExtra ./case3/device-ssh-c "root"
          {
            onStates = [ "my-state-factory-install" ];
            extraAuth.inherited = adC3F;
            # extraUsers.rawOverride = rawC2C3Users;
            cfgOverrides = cfgOvAllowInexistantDevUsrDef;
          };
      in
    {
      expr = listNamesOfSshUsersAuthorizedToDeviceUser ad;
      # We see here that the state only applies to this auth dir and not `adC3F`.
      expected = [ "my-ssh-user-c0" ];
    };

  testLoadAuthDirDeviceUserWExtraInheritedWPiecewiseMergeWAllowInexDef =
      let
        ad = loadAuthDirDeviceUserWExtra ./case3/device-ssh-c "root"
          {
            extraAuth.inherited = adC3FOnFactoryInstall;
            # extraUsers.rawOverride = rawC2C3Users;
            cfgOverrides.merge-policy = mPolOvAllowInexistantDevUsrDef // {
                device-user.inherited.authorized-set.merge-mismatching.method = "piecewise-mix";
              };
          };
      in
    {
      expr.unames = listNamesOfSshUsersAuthorizedToDeviceUser ad;
      expr.upk = listPubKeysContentOfSshUsersAuthorizedToDeviceUser ad;
      # We see here that the state only applies to this auth dir and not `adC3F`.
      expected.unames = map (x: "my-ssh-user-${x}") [ "c0" "f1" "f2" ];
      expected.upk = map (x: "c/.+/my-ssh-user-${x}.pub") [ "c0" ] ++ map (x: "f/.+/my-ssh-user-${x}.pub") [ "f1" "f2" ];
    };

  /*
  testLoadAuthDirDeviceUserWExtraInheritedAndOverride =
      let
        ad = loadAuthDirDeviceUserWExtra ./case3/device-ssh-c "root"
          {
            extraAuth.inherited = adC3FOnFactoryInstall;
            extraAuth.override = adC3DOnFactoryInstall;
            # extraUsers.rawOverride = rawC2C3Users;
          };
      in
    {
      expr.unames = listNamesOfSshUsersAuthorizedToDeviceUser ad;
      expr.upk = listPubKeysContentOfSshUsersAuthorizedToDeviceUser ad;
      # We see here that the state only applies to this auth dir and not `adC3F`.
      expected.unames = map (x: "my-ssh-user-${x}") [ "c0" "f1" "f2" ];
      expected.upk = map (x: "my-ssh-user-${x}") [ "c0" "f1" "f2" ];
    };
  */
}
