{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;
with usersModule;

let
  userSetC1 = loadUsersPlain defaultAuthDirCfg ./case1/device-ssh;
  uaC1 = userSetC1.sshUsers.my-ssh-user-a;
  ubC1 = userSetC1.sshUsers.my-ssh-user-b;

  userSetC2 = loadUsersPlain defaultAuthDirCfg ./case2/device-ssh;
  uaC2 = userSetC2.sshUsers.my-ssh-user-a;
  ubC2 = userSetC2.sshUsers.my-ssh-user-b;

  userSetC3C = loadUsersPlain defaultAuthDirCfg ./case3/device-ssh-c;
in

{
  testMergeSameNameUsersWMismatchingPubKeysDisallowedError = checkFails
    {
      expr = mergeSameNameUsers defUsersMergePolicy defUsersMergeOpts "my-user" uaC1 ubC1;
      expected = {};
    };

  testMergeSameNameUsersWSamePubKeysOkAsExactSame =
    {
      expr = mergeSameNameUsers defUsersMergePolicy defUsersMergeOpts "my-user" uaC1 uaC1;
      expected = uaC1;
    };

  testMergeSameNameUsersWMismatchingPubKeysOkWhenAllowed =
    {
      expr = mergeSameNameUsers inheritedUsersMergePolicy defUsersMergeOpts "my-user" uaC1 uaC2;
      expected = uaC2;
    };

  testMergeListOfUserSetsFromDiffOriginsOkWhenNoOverlap =
    {
      expr =
        let merged = (mergeListOfUserBundles defUsersMergePolicy [ userSetC1 userSetC3C ]); in
      {
        userNames = listUserNamesForSshUsers merged;
      };
      expected = {
        userNames = builtins.map (x: "my-ssh-user-${x}") [
          "a" "b" "c" "c0" "c1"  "c2"  "c3" "d" "e" "f" "g"
        ];
      };
    };
}
