{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {} }:

with pkgs;

let
  nixos-sf-data-deploy-tools = (import ../nixos-sf-data-deploy-tools/release.nix {
    inherit nixpkgs pkgs; }).release;

  release = callPackage ./. {
    inherit nixos-sf-data-deploy-tools;
  };

  env = buildEnv {
    name = "${release.pname}-env";
    paths = [ release ];
  };

  nixos-sf-test-lib = (
    import ../../../development/python-modules/nixos-sf-test-lib/release.nix { inherit pkgs; }).release;

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

  libTestInputs = release.buildInputs;

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
      pname = "${release.pname}-tests-${testName}";
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
  inherit env release;

  shell = {
    build = mkShell rec {
      name = "${release.pname}-build-shell";
      inputsFrom = [
        release
      ];
    };

    installed = mkShell rec {
      name = "${release.pname}-installed-shell";
      buildInputs = [
        env
      ];
    };

    dev = mkShell rec {
      name = "${release.pname}-dev-shell";
      inputsFrom = [
        release
      ];

      buildInputs = [
        devPython
      ];

      shellHook = ''
        export PATH="${builtins.toString ./bin}:$PATH"
        export "PYTHON_INTERPRETER=${devPython}/bin/python"
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
      inherit nixpkgs release nixos-sf-test-lib;
      inherit (pkgs) system;
      inherit commonGitIgnores;
    };

    all = [
      lib
      installed
      nixos
    ];

    aggregate = releaseTools.aggregate {
      name = "aggregated-tests-of-${release.name}";
      constituents = tests.all;
    };
  };
}
