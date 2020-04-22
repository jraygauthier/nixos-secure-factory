{ testTools
, sshAuthLib
}:

with testTools;
with sshAuthLib;
with groupsModule;

let
  gSetC2 = loadGroupsPlain defaultAuthDirCfg ./case2/device-ssh;
  g1 = gSetC2.sshGroups.my-group-1;
  g2 = gSetC2.sshGroups.my-group-2;

  gSetC3C = loadGroupsPlain defaultAuthDirCfg ./case3/device-ssh-c;
  gcAdmin = gSetC3C.sshGroups.my-group-c-admin;
in

{
  testMergeSameNameGroupsOfDiffMemberSetGroupsDisallowedError = checkFails
    {
      expr = mergeSameNameGroups defGroupsMergePolicy defGroupsMergeOpts "my-group" g1 g2;
      expected = {};
    };

  testMergeSameNameGroupsOfSameMemberSetGroupsOkWhenExactSame =
    {
      expr = mergeSameNameGroups defGroupsMergePolicy defGroupsMergeOpts "my-group" g1 g1;
      expected = g1;
    };

  testMergeSameNameGroupsOfDiffMemberSetGroupsOkWhenAllowedPiecewise =
    {
      expr =
        let merged = (mergeSameNameGroups inheritedGroupsMergePolicyWPiecewise defGroupsMergeOpts "my-group" g1 g2); in
      {
        members = merged.members;
        srcStr = merged.srcStr;
      };
      expected = {
        members = g1.members // g2.members;
        # This is as they come from the same file.
        srcStr = g2.srcStr;
      };
    };

  testMergeSameNameGroupsOfDiffMemberSetGroupsOkWhenAllowedPiecewiseDifferentOrigin =
    {
      expr =
        let merged = (mergeSameNameGroups inheritedGroupsMergePolicyWPiecewise defGroupsMergeOpts "my-group" g1 gcAdmin); in
      {
        members = merged.members;
        srcStr = merged.srcStr;
      };
      expected = {
        members = g1.members // gcAdmin.members;
        srcStr = "mergedSrcs[${g1.srcStr}:${gcAdmin.srcStr}]";
      };
    };


  testMergeSameNameGroupsOfDiffMemberSetGroupsOkWhenAllowedWholeOverride =
    {
      expr =
        let merged = (mergeSameNameGroups inheritedGroupsMergePolicy defGroupsMergeOpts "my-group" g1 g2); in
      {
        members = merged.members;
        srcStr = merged.srcStr;
      };
      expected = {
        members = g2.members;
        srcStr = g2.srcStr;
      };
    };

  testMergeSameNameGroupsOfDiffMemberSetGroupsOkWhenAllowedWholeOverrideDifferentOrigin =
    {
      expr =
        let merged = (mergeSameNameGroups inheritedGroupsMergePolicy defGroupsMergeOpts "my-group" g1 gcAdmin); in
      {
        members = merged.members;
        srcStr = merged.srcStr;
      };
      expected = {
        members = gcAdmin.members;
        srcStr = gcAdmin.srcStr;
      };
    };

  testMergeListOfGroupSetsFromDiffOriginsOk =
    {
      expr =
        let merged = (mergeListOfGroupBundles defGroupsMergePolicy [ gSetC2 gSetC3C ]); in
      {
        groupNames = listGroupNamesForSshGroups merged;
      };
      expected = {
        groupNames = builtins.map (x: "my-group-${x}") [
          "1" "2" "3"
          "c-admin" "c-dev" "c-support"
        ];
      };
    };
}
