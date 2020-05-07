{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {}
}:

let
  release =
    import ../../release.nix {
      inherit pkgs;
  };

  dataDeployLib = release.nix-lib;
in

with dataDeployLib; with dataDeployLib.impl; rec {

  loadDeviceDataDeployBundle = data0: data1: data2: data3: data4: data5:
    loadResolvedDataDeployBundle data0 {
        defaultImportsFn = dd:
          let
            defImportsMap = {
              "${toString data0}" = [ data1 ];
              "${toString data1}" = [
                {
                  path = data2; allow-inexistent = false;
                }
              ];
              "${toString data3}" = [
                {
                  path = data4; allow-inexistent = true;
                }
              ];
            };

            ddStr = toString dd;

            defImports =
              if defImportsMap ? "${ddStr}"
                then defImportsMap."${ddStr}"
                else [];
          in
            defImports;
    };

  myDeviceResolvedBundle = loadDeviceDataDeployBundle ./data0 ./data1 ./data2 ./data3 ./data4 ./data5;
  myDeviceResolvedBundleAsJson = writeToPrettyJson "debug.json" myDeviceResolvedBundle;
  myDerivationResolvedBundle = mkDerivationResolvedBundleFromResolvedBundle myDeviceResolvedBundle;
  myDerivationResolvedBundleAsJson =
    writeResolvedBundleToPrettyJson "deploy.json" myDerivationResolvedBundle;

  myRulesInstallScript = writeRulesInstallScript myDeviceResolvedBundle;
  myRulesDeployScript = writeRulesDeployScript myDerivationResolvedBundle;

  myDeviceDataDeployDerivation = mkDataDeployDerivationFromResolvedBundle myDeviceResolvedBundle;
}