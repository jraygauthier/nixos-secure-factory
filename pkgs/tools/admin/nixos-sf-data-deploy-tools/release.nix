{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {} }:

with pkgs;

let
  release = callPackage ./. {};
  env = buildEnv {
    name = "${release.pname}-env";
    paths = [ release ];
  };

  nixos-sf-test-lib = (
    import ../../../development/python-modules/nixos-sf-test-lib/release.nix { inherit pkgs; }).release;

  testPython = python3.withPackages (pp: with pp; [
    pytest
    nixos-sf-test-lib
  ]);

  devPython = python3.withPackages (pp: with pp; [
    ipython
    pytest
    nixos-sf-test-lib
  ]);

  libTestInputs = release.buildInputs;

  installedTestInputs = [
    env
  ];

  commonGitIgnores = [
    ../../../../.gitignore
    ''
      *.nix
    ''
  ];

  mkTest = { testName, runTimeDeps, testPath, extraGitIgnores ? ""}:
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
    lib = mkTest rec {
      testName = "lib";
      runTimeDeps = libTestInputs;
      testPath = "./tests/${testName}";
      extraGitIgnores = ''
        /bin/
      '';
    };

    installed = mkTest rec {
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
      system = "x86_64-linux";
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
