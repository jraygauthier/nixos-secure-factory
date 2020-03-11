{ lib
, buildPythonPackage
, nix-gitignore
, pytest
, ipython
, flake8
, mypy
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
  ];

  checkPhase = ''
    mypy .
    pytest .
    flake8
  '';

  propagatedBuildInputs = [
  ];

  shellHook = ''
    setuptoolsShellHook
  '';

  passthru = {
    inherit pname version;
  };
}
