{ nixpkgs ? null
, pkgs ? import (if null != nixpkgs then nixpkgs else <nixpkgs>) {}
} @ args:

with pkgs;

let
  nixpkgs = if args ? "nixpkgs" then nixpkgs else <nixpkgs>;
  nsf-data-deploy-tools = (import ../nsf-data-deploy-tools/release.nix {
    inherit nixpkgs pkgs; }).default;

  default = callPackage ./. {
    inherit nsf-data-deploy-tools;
  };

  env = buildEnv {
    name = "${default.pname}-env";
    paths = [ default ];
  };

  nsf-test-lib-root-dir = ../../../development/python-modules/nsf-test-lib;

  nsf-test-lib = (
    import (nsf-test-lib-root-dir + "/release.nix") { inherit pkgs; }).default;

  nixTestLib = nsf-test-lib.nixLib;

  commonPythonPkgsFn = pp: with pp; [
    pytest
    nsf-test-lib
  ];

  testPython = python3.withPackages commonPythonPkgsFn;

  devPython = python3.withPackages (pp: with pp; commonPythonPkgsFn pp ++ [
    ipython
    mypy
    flake8
  ]);

  libTestInputs = default.buildInputs ++ [default];

  installedTestInputs = [
    env
  ];

  commonGitIgnores = [
    ../../../../../.gitignore
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
        if [[ "1" != "''${IN_NIX_SHELL+1}" ]]; then
          export "NIXOS_SF_TEST_LIB_NO_DIR_CACHE=1"
        fi
        export "NIXOS_SF_TEST_LIB_BIN_PATH=${coreutils}/bin:${gnupg}/bin"
        pytest --color=yes "${testPath}" | tee ./pytest.log
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
        shellcheck
      ];

      shellHook = ''
        export PATH="${builtins.toString ./bin}:$PATH"
        export "PYTHON_INTERPRETER=${devPython}/bin/python"
        export "NIXOS_SF_TEST_LIB_BIN_PATH=${coreutils}/bin:${gnupg}/bin"

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
        local_nix_sf_test_lib_root_dir="${builtins.toString nsf-test-lib-root-dir}"
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
      inherit nixpkgs default nsf-test-lib;
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
