{ nixpkgs ? null
, pkgs ? import (if null != nixpkgs then nixpkgs else <nixpkgs>) {}
} @ args:

with pkgs;

let
  nixpkgs = if args ? "nixpkgs" then nixpkgs else <nixpkgs>;
  default = callPackage ./. {};
  env = buildEnv {
    name = "${default.pname}-env";
    paths = [ default ];
  };

  nixos-sf-test-lib = (
    import ../../../development/python-modules/nixos-sf-test-lib/release.nix { inherit pkgs; }).default;

  nixTestLib = nixos-sf-test-lib.nixLib;

  commonPythonPkgsFn = pp: with pp; [
    pytest
    nixos-sf-test-lib
  ];

  testPython = python3.withPackages commonPythonPkgsFn;

  devPython = python3.withPackages (pp: with pp; commonPythonPkgsFn pp ++ [
    ipython
    mypy
    flake8
  ]);

  libTestInputs = default.buildInputs;

  installedTestInputs = [
    env
  ];

  commonGitIgnores = [
    ../../../../.gitignore
    "*.nix\n"
  ];

  mkPyTest = { testName, runTimeDeps, testPath, extraGitIgnores ? ""}:
    assert lib.isString testPath;
    stdenv.mkDerivation rec {
      pname = "${default.pname}-tests-${testName}";
      name = pname;
      src = nix-gitignore.gitignoreSourcePure (commonGitIgnores ++ [
        ''
          /Makefile
          /README.md
        ''
        extraGitIgnores
        ]) ./.;
      buildInputs = [ testPython ] ++ runTimeDeps;

      buildPhase = ''
        pytest --color=yes ${testPath} | tee ./pytest.log
      '';

      installPhase = ''
        mkdir -p "$out"
        cp -t "$out" ./pytest.log
      '';
    };
in

rec {
  inherit env default;

  shell = {
    build = mkShell rec {
      name = "${default.pname}-build-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [
        default
      ];
    };

    installed = mkShell rec {
      name = "${default.pname}-installed-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      buildInputs = [
        env
      ];
    };

    dev = mkShell rec {
      name = "${default.pname}-dev-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [
        default
      ];

      buildInputs = [
        devPython
      ];

      shellHook = ''
        export PATH="${builtins.toString ./bin}:$PATH"
        export "PYTHON_INTERPRETER=${devPython}/bin/python"
        # Workaround for 'mypy/issues/5701'.
        pythonV='${lib.strings.substring 0 3 (lib.strings.getVersion devPython.name)}'
        export "MYPYPATH=${devPython}/lib/python''${pythonV}/site-packages"
      '';
    };
  };

  tests = rec {
    lib = mkPyTest rec {
      testName = "lib";
      runTimeDeps = libTestInputs;
      testPath = "./tests/${testName}";
      extraGitIgnores = ''
        /bin/
      '';
    };

    installed = mkPyTest rec {
      testName = "installed";
      runTimeDeps = installedTestInputs;
      testPath = "./tests/${testName}";
      extraGitIgnores = ''
        /bin/
        /sh-lib/
      '';
    };

    nixos = import ./tests/nixos/test-system-installed-binaries.nix {
      inherit nixpkgs default nixos-sf-test-lib;
      inherit (pkgs) system;
      inherit commonGitIgnores;
    };

    all = [
      lib
      installed
      nixos
    ];

    aggregate = releaseTools.aggregate {
      name = "aggregated-tests-of-${default.name}";
      constituents = tests.all;
    };
  };
}
