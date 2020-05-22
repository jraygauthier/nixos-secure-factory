{ lib
, buildPythonPackage
, mypy
, pytest
, flake8
, ipython
, click
, pyyaml
, nsf-shell-complete-nix-lib
, nixos-sf-factory-common-install-py
, nixos-sf-ssh-auth-cli
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
    nixos-sf-ssh-auth-cli
  ];

  postInstall = with nsf-shell-complete-nix-lib; ''
    ${shComp.pkg.installClickExesBashCompletion [
    ]}
  '';

  # Allow nix-shell inside nix-shell.
  # See `pkgs/development/interpreters/python/hooks/setuptools-build-hook.sh`
  # for the reason why.
  shellHook = ''
    setuptoolsShellHook
  '';
}
