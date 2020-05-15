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
  pname = "nixos-sf-test-lib";
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

  # TODO: Reactivate this only once we found a way to
  # garbage collect gpg agents launched over the various test directories.
  doCheck = false;

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
