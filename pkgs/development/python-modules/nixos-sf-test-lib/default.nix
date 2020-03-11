{ lib
, buildPythonPackage
, nix-gitignore
, pytest
, ipython
, flake8
, mypy
, gnupg
}:

buildPythonPackage rec  {
  pname = "nixos-sf-data-deploy-python-lib";
  version = "0.0.0";
  src = nix-gitignore.gitignoreSourcePure [
    ../../../../.gitignore
    ''
      *.nix
      /nix-lib/
    ''
    ] ./.;
  buildInputs = [];
  checkInputs = [
    flake8
    mypy
    pytest
    gnupg
  ];

  checkPhase = ''
    mypy .
    pytest .
    flake8
  '';

  propagatedBuildInputs = [
    gnupg
  ];

  shellHook = ''
    setuptoolsShellHook
  '';

  passthru = {
    inherit pname version;
  };
}
