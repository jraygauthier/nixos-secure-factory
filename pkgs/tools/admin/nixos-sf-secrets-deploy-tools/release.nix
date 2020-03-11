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

  nixos-sf-test-lib-root-dir = ../../../development/python-modules/nixos-sf-test-lib;

  nixos-sf-test-lib = (
    import (nixos-sf-test-lib-root-dir + "/release.nix") { inherit pkgs; }).release;

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

        # TODO: Make this more concise while avoiding the vscode debugger issue
        # observed when using the bash colon trick.
        prefix_path() {
          local varname="''${1?}"
          local -n old_value="''${1?}"
          local prefixed_value="''${2?}"
          if [[ -z "''${old_value}" ]]; then
            export "''${varname}=$prefixed_value"
          else
            export "''${varname}=$prefixed_value:''${old_value}"
          fi
        }

        # Workaround for 'mypy/issues/5701'.
        pythonV='${lib.strings.substring 0 3 (lib.strings.getVersion devPython.name)}'
        prefix_path "MYPYPATH" "${devPython}/lib/python''${pythonV}/site-packages"

        # Make our development workflow easier when possible.
        local_nix_sf_test_lib_root_dir="${builtins.toString nixos-sf-test-lib-root-dir}"
        if [[ -e "$local_nix_sf_test_lib_root_dir" ]]; then
          prefix_path "PYTHONPATH" "$local_nix_sf_test_lib_root_dir/src"
          prefix_path "MYPYPATH" "$local_nix_sf_test_lib_root_dir/src"
        fi
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
