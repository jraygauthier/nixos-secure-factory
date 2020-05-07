{ pkgs ? import <nixpkgs> {}}:

let
  release =
    import ../../release.nix {
      inherit pkgs;
  };

  bundleDir = ./device/my-device-id/data-override;

  deviceDataOverride = ./device/my-device-id/data-override;
  deviceData = ./device/my-device-id/data;
  deviceTypeData = ./device-type/my-device-type/data;
  deviceFamilyData = ./device-family/my-device-family/data;
  deviceBaseFamilyData = ./device-family/my-device-base-family/data;


  defaultImportsFn = currentDataBundleDir:
    let
      mkOptBaseImports = path: [{
        inherit path;
        allow-inexistent = true;
      }];
      defImportsMap = {
        "${toString deviceDataOverride}" = mkOptBaseImports deviceData;
        "${toString deviceData}" = mkOptBaseImports deviceTypeData;
        "${toString deviceTypeData}" = mkOptBaseImports deviceFamilyData;
        "${toString deviceFamilyData}" = mkOptBaseImports deviceBaseFamilyData;
      };

      currentDataBundleDirStr = toString currentDataBundleDir;

      defImports =
        if defImportsMap ? "${currentDataBundleDirStr}"
          then defImportsMap."${currentDataBundleDirStr}"
          else [];
    in
      defImports;

  deviceDataDeployDerivation =
    release.mkDataDeployPackage {
      inherit bundleDir defaultImportsFn;
  };
in {
  myDeviceDataDeployDerivation = deviceDataDeployDerivation;
}