{ lib
, buildPythonPackage
, mypy
, pytest
, flake8
, ipython
, click
, pyyaml
, nixos-sf-factory-common-install-py
}:

let
  bashCompletionLib = (import ../../../lib/default.nix {}).bashCompletions {
    inherit lib;
  };
in

buildPythonPackage rec  {
  pname = "nixos-sf-factory-install-py";
  version = "0.0.0";
  src = ./.;
  buildInputs = [];
  checkInputs = [
    mypy
    pytest
    flake8
  ];

  doCheck = false;

  checkPhase = ''
    mypy .
    pytest .
    flake8
  '';

  propagatedBuildInputs = [
    click
    pyyaml
    nixos-sf-factory-common-install-py
  ];

  postInstall = ''
    ${bashCompletionLib.installClickExesBashCompletion [
    ]}
  '';

  # Allow nix-shell inside nix-shell.
  # See `pkgs/development/interpreters/python/hooks/setuptools-build-hook.sh`
  # for the reason why.
  shellHook = ''
    setuptoolsShellHook
  '';
}
