{ dataBundleDir
, defaultImportsFn ? dataBundleDir: []
, nixpkgs ? import <nixpkgs> {}
}:

let
  dataDeployLib = import ./nix-lib/release.nix {
    inherit nixpkgs;
  };
  dataDeployDerivation = dataDeployLib.mkDataDeployDerivation dataBundleDir {
    inherit defaultImportsFn;
  };
in
  dataDeployDerivation
