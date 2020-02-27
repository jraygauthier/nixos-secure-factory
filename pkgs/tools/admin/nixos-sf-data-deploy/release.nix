{ dataBundleDir
, defaultImportsFn ? dataBundleDir: []
, nixpkgs ? import <nixpkgs> {}
}:

let
  dataDeployLib = import ../nixos-sf-data-deploy-lib/release.nix {
    inherit nixpkgs;
  };
  dataDeployDerivation = dataDeployLib.mkDataDeployDerivation dataBundleDir {
    inherit defaultImportsFn;
  };
in
  dataDeployDerivation
