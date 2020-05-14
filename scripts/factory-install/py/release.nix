{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs)
    lib
    callPackage
    python3
    python3Packages
    mkShell
    bash-completion
    writeShellScript;

  repoRootDir = ../../..;

  nixos-sf-shell-complete-nix-lib = (import (
    repoRootDir + "/pkgs/build-support/nixos-sf-shell-complete/release.nix") {
      inherit pkgs;
    }).nix-lib;

  sffciPyRelease = (import
    (repoRootDir + "/scripts/factory-common-install/release.nix") {
      inherit pkgs;
    }).py-release;

  nixos-sf-factory-common-install-py =
    sffciPyRelease.default;

  nixos-sf-test-lib = (import
    (repoRootDir + "/pkgs/development/python-modules/nixos-sf-test-lib/release.nix") {
      inherit pkgs;
    }).default;

  pythonPackages = pkgs.python3Packages;

  default = pythonPackages.callPackage ./. {
    inherit nixos-sf-shell-complete-nix-lib;
    inherit nixos-sf-factory-common-install-py;
  };

  env = mkShell {
    name = "${default.pname}-env";

    PYTHONPATH = "";
    MYPYPATH = "";

    buildInputs = [ default ];

    shellHook = with nixos-sf-shell-complete-nix-lib; ''
      ${shComp.env.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
      ${shComp.env.ensureDynamicBashCompletionLoaderInstalled}
    '';
  };


  sfRepoLocalRootDir = repoRootDir;

  sfTestLibLocalSrcDir = sfRepoLocalRootDir
    + "/pkgs/development/python-modules/nixos-sf-test-lib/src";

  sffciPyLocalSrcDir = sfRepoLocalRootDir
    + "/scripts/factory-common-install/py/src";

  shellHookLib = writeShellScript "python-project-shell-hook-lib.sh" ''
    source "${sffciPyRelease.shell-hook-lib}"

    sh_hook_py_add_local_pkg_src_nixos_sf_test_lib() {
      sh_hook_py_add_local_pkg_src_if_present \
        "${builtins.toString sfTestLibLocalSrcDir}"
    }

    sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py() {
      sh_hook_py_add_local_pkg_src_if_present \
        "${builtins.toString sffciPyLocalSrcDir}"
    }

    sh_hook_py_add_local_pkg_src_nixos_sf_factory_install_py() {
      sh_hook_py_add_local_pkg_src_if_present \
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
      sh_hook_py_set_interpreter_env_from_path
      # sh_hook_lib_mypy_5701_workaround_from_path
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
