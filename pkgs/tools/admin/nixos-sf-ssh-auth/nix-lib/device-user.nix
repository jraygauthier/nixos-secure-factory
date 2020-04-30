
{ lib
, stdenv
, yq
} @ args:

let
  callPackage = lib.callPackageWith args;
  coreModule = callPackage ./core.nix {};
  loaderModule = callPackage ./loader.nix {};
  usersModule = callPackage ./users.nix {};
  authModule = callPackage ./auth.nix {};

in

with coreModule;
with loaderModule;
with usersModule;
with authModule;

rec {

  defFinalDeviceUserMergeOpts = {};

  ensureValidMPolFinalDeviceUserDefinitionCfg = {
        # Allow that the requested *final user* be missing, fallbacking on
        # the `""` definition. When `false`, an error will be raised.
        allow-missing ? false
      }:
    {
      inherit allow-missing;
    };


  defMPolFinalDeviceUserDefinitionCfg = ensureValidMPolFinalDeviceUserDefinitionCfg {};


  ensureValidMPolFinalDeviceUserAuthorizedSetCfg = {
        # A list of *device users* for which an error will be raised in case
        # no *ssh user* is authorized to the final / resulting *device user*.
        forbid-empty-for ? []
      }:
    {
      inherit forbid-empty-for;
    };


  defMPolFinalDeviceUserAuthorizedSetCfg = ensureValidMPolFinalDeviceUserAuthorizedSetCfg {};


  # This policy specifies how to merge the *final device user* using the special
  # `""` (all users) *device user* definition with the *device user* definition matching
  # the specified *device username*.
  ensureValidFinalDeviceUserMergePolicy = {
        # How to merge ssh users when merging 2 auth.
        ssh-user ? defUsersMergePolicy,
        device-user-definition ? defMPolFinalDeviceUserDefinitionCfg,
        authorized-set ? defMPolFinalDeviceUserAuthorizedSetCfg
      }:
    {
      ssh-user = ensureValidUsersMergePolicy ssh-user;
      device-user-definition = ensureValidMPolFinalDeviceUserDefinitionCfg device-user-definition;
      authorized-set = ensureValidMPolFinalDeviceUserAuthorizedSetCfg authorized-set;
    };

  defFinalDeviceUserMergePolicy = ensureValidFinalDeviceUserMergePolicy {};


  internalFinalDeviceUserMergePolicy = defFinalDeviceUserMergePolicy;


  mergeFinalDeviceUserFromDeviceUserValues = fdumPol: opts: xdu: ydu:
    assert isDeviceUserValue xdu;
    assert hasName xdu;
    assert isDeviceUserValue ydu;
    assert hasName ydu;
      let
        fdumPolValid = ensureValidAuthMergePolicy fdumPol;
        # TODO: We might want to develop custom code here to improve error messages.
      in
    {
      # TODO: Specialize `defUsersMergeOpts` in order to improve error messages.
      sshUsers = mergeUserAttrSets fdumPol.ssh-user defUsersMergeOpts xdu.sshUsers ydu.sshUsers;
      srcStr = mergeSrcStrList [xdu.srcStr ydu.srcStr];
    };


  mergeFinalDeviceUserFromListOfDeviceUserValues = fdumPol: opts: xs:
    if [] == xs
      then
        {
          sshUsers = {};
          srcStr = "mergedSrcs[]";
        }
      else
        lib.lists.foldl' (mergeFinalDeviceUserFromDeviceUserValues fdumPol opts) (lib.lists.head xs) (lib.lists.tail xs);


  mkNamedDeviceUser = deviceUserName: deviceUserValue:
    deviceUserValue // {
        name = deviceUserName;
    };


  mkDeviceUserFromAuth = mPol: auth: deviceUsername:
      let
        dus = auth.deviceUsers;
        validUsername = "" != deviceUsername;
        existDeviceUserDefinition = dus ? "${deviceUsername}";
        fdumPol = mPol.final-device-user.internal;
        emptyAuthSetAllowed = !(
          lib.lists.elem deviceUsername fdumPol.authorized-set.forbid-empty-for);
        authFilesStr = printSrcFilesStrForSrcs "\n" auth.srcs;
      in
    assert lib.asserts.assertMsg (validUsername)
      "Invalid \"final\" device username: '${deviceUsername}'.";
    assert lib.asserts.assertMsg (fdumPol.device-user-definition.allow-missing || existDeviceUserDefinition)
      ( "Inexistant \"device user\" definition for specified username '${deviceUsername}'.\n"
      + "Current \"final device user\" merge policy does not allow this.\n"
      + "You can either set the policy's 'device-user-definition.allow-missing' flag true "
      + "or provide a definition for '${deviceUsername}' "
      + "in one of the following files: ''\n${authFilesStr}\n''"
      );

      let
        users = mergeFinalDeviceUserFromListOfDeviceUserValues fdumPol defFinalDeviceUserMergeOpts ([]
          ++ lib.lists.optional (dus ? "") (
            mkNamedDeviceUser "" dus."")
          ++ lib.lists.optional (validUsername && dus ? "${deviceUsername}") (
            mkNamedDeviceUser deviceUsername dus."${deviceUsername}")
          );
        duSrcStr = users.srcStr;
        authSetEmpty = {} == users.sshUsers;
      in
    assert lib.asserts.assertMsg (emptyAuthSetAllowed || !authSetEmpty)
      ( "Empty \"final device user\" authorized user set detected for specified "
      + "username '${deviceUsername}' from '${duSrcStr}'.\n"
      + "Current \"final device user\" merge policy does not allow this.\n"
      + "You can either remove this user from the policy's 'authorized-set.forbid-empty-for' list "
      + "or authorize at least a single \"ssh user\" to \"device user\" with username '${deviceUsername}' "
      + "in one of the following files: ''\n${authFilesStr}\n''"
      );
    {
      srcs = auth.srcs;
      deviceUser = {
        name = deviceUsername;
        inherit (users) sshUsers srcStr;
      };
    };


  isDeviceUser = devUserAuth:
       devUserAuth ? "deviceUser"
    && devUserAuth.deviceUser ? "sshUsers";


  getDeviceUserName = devUserAuth:
    assert isDeviceUser devUserAuth;
    devUserAuth.deviceUser.name;


  getSshUsersAuthorizedToDeviceUser = devUserAuth:
    mkSshUsers devUserAuth.deviceUser.sshUsers;


  listNamesOfSshUsersAuthorizedToDeviceUser = devUserAuth:
    assert isDeviceUser devUserAuth;
    listUserNamesForSshUsers (getSshUsersAuthorizedToDeviceUser devUserAuth);


  listPubKeysOfSshUsersAuthorizedToDeviceUser = devUserAuth:
    assert isDeviceUser devUserAuth;
    listPubKeysForSshUsers (getSshUsersAuthorizedToDeviceUser devUserAuth);


  listPubKeysContentOfSshUsersAuthorizedToDeviceUser = devUserAuth:
    assert isDeviceUser devUserAuth;
    listPubKeysContentForSshUsers (getSshUsersAuthorizedToDeviceUser devUserAuth);
}
