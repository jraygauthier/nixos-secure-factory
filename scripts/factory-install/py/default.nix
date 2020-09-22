{ lib
, buildPythonPackage
, mypy
, pytest
, flake8
, ipython
, click
, pyyaml
, nsf-shc-nix-lib
, nixos-sf-factory-common-install-py
}:

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

  postInstall = with nsf-shc-nix-lib; ''
    ${nsfShC.pkg.installClickExesBashCompletion [
    ]}
  '';

  # Allow nix-shell inside nix-shell.
  # See `pkgs/development/interpreters/python/hooks/setuptools-build-hook.sh`
  # for the reason why.
  shellHook = ''
    setuptoolsShellHook
  '';
}
