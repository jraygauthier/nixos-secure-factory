{ pkgs ? null } @ args:

let
  repoRootDir = ../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
in

with pkgs;

let
  pyRelease = import
    ./py/release.nix {
      inherit pkgs;
    };

  nsf-factory-common-install-py = pyRelease.default;

  default = (callPackage ./. {
    inherit nsf-shc-nix-lib;
    inherit nsf-common-install;
    inherit nsf-device-system-config;
    inherit nsf-device-system-config-updater;
    inherit nsf-factory-common-install-py;
  } // {
    envShellHook = writeScript "envShellHook.sh" ''
    '';
  });

  env = buildEnv {
    name = "${default.pname}-build-env";
    paths = [ default ];
  };

  # defaultPython = default.python-interpreter;
  devPython = python3.withPackages (pp: with pp; (
      default.python-packages ++ [
    pytest
    mypy
    flake8
    ipython
  ]));


  pyShellHookLib = pyRelease.shell-hook-lib;
in

rec {
  inherit default env;
  py-release = pyRelease;
  python-lib = pyRelease.default;

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
      buildInputs = [
        env
        dieHook
      ];

      PYTHONPATH = "";
      MYPYPATH = "";

      shellHook = with nsf-shc-nix-lib; ''
        source "${default.envShellHook}"

        ${nsfShC.env.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
        ${nsfShC.env.ensureDynamicBashCompletionLoaderInstalled}

        shell_dir="${toString ./.}"
        test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

        export "PKG_NSF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
        . "$shell_dir/env.sh"

        export PKG_NSF_FACTORY_COMMON_INSTALL_IN_ENV=1
      '';

      passthru.shellHook = shellHook;
    };

    dev = mkShell rec {
      name = "${default.pname}-dev-shell";
      inputsFrom = [
        default
      ];

      buildInputs = [
        dieHook
        devPython
        shellcheck
      ];

      PYTHONPATH = "";
      MYPYPATH = "";

      shellHook = ''
        shell_dir="${toString ./.}"
        test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

        export "PKG_NSF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
        . "$shell_dir/env.sh"

        export PKG_NSF_FACTORY_COMMON_INSTALL_IN_BUILD_ENV=1
        export PKG_NSF_FACTORY_COMMON_INSTALL_IN_ENV=1

        export PATH="${builtins.toString ./bin}:$PATH"

        source ${pyShellHookLib}
        nsf_py_set_interpreter_env_from_nix_store_path "${devPython}"
        nsf_py_mypy_5701_workaround "${devPython}"
        sh_hook_py_add_local_pkg_src_nixos_sf_test_lib
        sh_hook_py_add_local_pkg_src_nixos_sf_ssh_auth_cli
        sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py
      '';
    };
  };
}
