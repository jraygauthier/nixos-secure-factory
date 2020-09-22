{ pkgs ? null } @ args:

let
  repoRootDir = ../../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
in

with pkgs;

let
  sffciPyRelease = (import
    (repoRootDir + "/scripts/factory-common-install/release.nix") {
      inherit pkgs;
    }).py-release;

  nixos-sf-factory-common-install-py =
    sffciPyRelease.default;

  pythonPackages = pkgs.python3Packages;

  default = pythonPackages.callPackage ./. {};

  env = mkShell {
    name = "${default.pname}-env";

    PYTHONPATH = "";
    MYPYPATH = "";

    buildInputs = [ default ];

    shellHook = with nsf-shc-nix-lib; ''
      ${nsfShC.env.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
      ${nsfShC.env.ensureDynamicBashCompletionLoaderInstalled}
    '';
  };


  sfRepoLocalRootDir = repoRootDir;

  sfTestLibLocalSrcDir = sfRepoLocalRootDir
    + "/.nix/pkgs/development/python-modules/nixos-sf-test-lib/src";

  sffciPyLocalSrcDir = sfRepoLocalRootDir
    + "/scripts/factory-common-install/py/src";

  shellHookLib = with nsf-py-nix-lib; writeShellScript "python-project-shell-hook-lib.sh" ''
    source "${sffciPyRelease.shell-hook-lib}"

    sh_hook_py_add_local_pkg_src_nixos_sf_test_lib() {
      nsf_py_add_local_pkg_src_if_present \
        "${builtins.toString sfTestLibLocalSrcDir}"
    }

    sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py() {
      nsf_py_add_local_pkg_src_if_present \
        "${builtins.toString sffciPyLocalSrcDir}"
    }

    sh_hook_py_add_local_pkg_src_nixos_sf_factory_install_py() {
      nsf_py_add_local_pkg_src_if_present \
        "${builtins.toString ./src}"
    }
  '';

  dev = default.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs
      ++ (with pythonPackages; [
        pytest
        mypy
        flake8
        ipython
      ]);

    shellHook = ''
      ${oldAttrs.shellHook}
      source ${shellHookLib}
      nsf_py_set_interpreter_env_from_path
      # nsf_py_mypy_5701_workaround
      sh_hook_py_add_local_pkg_src_nixos_sf_test_lib
      sh_hook_py_add_local_pkg_src_nixos_sf_ssh_auth_cli
      sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py
    '';
  });
in

rec {
  inherit env default;

  shell = {
    dev = mkShell rec {
      name = "${default.pname}-dev-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [dev];
    };
  };

  shell-hook-lib = shellHookLib;
}
