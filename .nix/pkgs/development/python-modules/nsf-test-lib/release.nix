{ pkgs ? import <nixpkgs> {} }:

with pkgs;

rec {
  nixLib = callPackage ./nix-lib {};

  pythonPackages = pkgs.python3Packages;

  default = pythonPackages.callPackage ./. {};

  dev = default.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ (with pythonPackages; [
      ipython
      pytest
      mypy
      flake8
    ]);

    shellHook = ''
      ${oldAttrs.shellHook}
      pythonInterpreter="$(which python)"
      export "PYTHON_INTERPRETER=$pythonInterpreter"
      export "NSF_TEST_LIB_BIN_PATH=${coreutils}/bin:${pkgs.gnupg}/bin"

      check_all() {
        mypy . && pytest . && flake8
      }
    '';
  });

  shell = {
    dev = mkShell rec {
      name = "${default.pname}-dev-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [dev];
    };
  };
}
