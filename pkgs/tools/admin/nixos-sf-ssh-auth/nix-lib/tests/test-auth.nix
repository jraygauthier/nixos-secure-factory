{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;
with authModule;

let
  authC1 = loadAuthPlain defaultAuthDirCfg ./case1/device-ssh [];
  duC1a = authC1.deviceUsers."my-device-user-a";

  authC2 = loadAuthPlain defaultAuthDirCfg ./case2/device-ssh [];
  duC2a = authC2.deviceUsers."my-device-user-a";
in

{
  testMergeSameNameDeviceUsersOfDifferentSshUserSetDisallowedError = checkFails
    {
      expr = mergeSameNameDeviceUsers internalAuthMergePolicy defDeviceUsersMergeOpts "my-device-user" duC1a duC2a;
      expected = null;
    };

  testMergeSameNameDeviceUsersOfSameSshUserSetOk =
    {
      expr = mergeSameNameDeviceUsers internalAuthMergePolicy defDeviceUsersMergeOpts "my-device-user" duC1a duC1a;
      expected = duC1a;
    };

  testMergeSameNameDeviceUsersOfDifferentSshUserSetOkWhenAllowed =
    {
      expr = mergeSameNameDeviceUsers inheritedAuthMergePolicy defDeviceUsersMergeOpts "my-device-user" duC1a duC2a;
      # As `duC2a` is rhs, it completely hides lhs as it is a superset.
      expected = duC2a;
    };

  testMergeSameNameDeviceUsersOfDifferentSshUserSetOkWhenAllowedSwapedArgsDefaultMerge =
    {
      expr = mergeSameNameDeviceUsers inheritedAuthMergePolicy defDeviceUsersMergeOpts "my-device-user" duC2a duC1a;
      # Rhs has precedance and with default inherit merge behavior, it **completely** override lhs.
      expected = duC1a;
    };

  testMergeSameNameDeviceUsersOfDifferentSshUserSetOkWhenAllowedSwapedArgsWPiecewiseMerge =
    {
      expr = mergeSameNameDeviceUsers inheritedAuthMergePolicyWPiecewise defDeviceUsersMergeOpts "my-device-user" duC2a duC1a;
      expected = {
        srcStr = "mergedSrcs[${duC2a.srcStr}:${duC1a.srcStr}]";
        sshUsers = {
          # Rhs has precedance and with piecewise merge strategy opted-in can now **partially** override lhs.
          "my-ssh-user-a" = duC1a.sshUsers.my-ssh-user-a;
          "my-ssh-user-b" = duC2a.sshUsers.my-ssh-user-b;
        };
      };
    };
}
