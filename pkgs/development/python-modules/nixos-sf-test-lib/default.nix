{ lib, buildPythonPackage
, pytest, ipython
, fromNixShell ? false }:

buildPythonPackage rec  {
  pname = "nixos-sf-data-deploy-python-lib";
  version = "0.0.0";
  src = ./.;
  buildInputs = [];
  checkInputs = [
    pytest
  ] ++ lib.optionals fromNixShell [
    ipython
  ];

  checkPhase = ''
    pytest .
  '';

  propagatedBuildInputs = [
  ];
}
