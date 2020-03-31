{ pkgs ? import <nixpkgs> {} }:
with pkgs; rec {
  nixLib = callPackage ./nix-lib {};

  pythonPackages = pkgs.python3Packages;

  release = pythonPackages.callPackage ./. {};

  shell = {
    dev = mkShell rec {
      name = "${release.pname}-dev-shell";

      inputsFrom = [
        (release.overrideAttrs (oldAttrs: {
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
          export "NIXOS_SF_TEST_LIB_BIN_PATH=${coreutils}/bin:${pkgs.gnupg}/bin"

          check_all() {
            mypy . && pytest . && flake8
          }
        '';
        }))
      ];
    };
  };
}
