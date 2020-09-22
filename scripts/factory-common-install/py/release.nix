{ pkgs ? null } @ args:

let
  repoRootDir = ../../..;
  pkgs = (import (
      repoRootDir + "/.nix/release.nix") {}
    ).ensurePkgs args;
  wsRootDir = repoRootDir + "/..";
in

with pkgs;

let
  pythonPackages = python3Packages;

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

  sfTestLibRootDir = repoRootDir + "/.nix/pkgs/development/python-modules/nixos-sf-test-lib";
  sfTestLibLocalSrcDir = sfTestLibRootDir + "/src";

  sfSshAuthCliLocalSrcDir = wsRootDir + "/nsf-ssh-auth/cli/src";

  shellHookLib = with nsf-py-nix-lib; writeShellScript "python-project-shell-hook-lib.sh" ''
      source ${nsfPy.shell.shellHookLib}

      sh_hook_py_add_local_pkg_src_nixos_sf_test_lib() {
        nsf_py_add_local_pkg_src_if_present \
          "${builtins.toString sfTestLibLocalSrcDir}"
      }

      sh_hook_py_add_local_pkg_src_nixos_sf_ssh_auth_cli() {
        nsf_py_add_local_pkg_src_if_present \
          "${builtins.toString sfSshAuthCliLocalSrcDir}"
      }

      sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py() {
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
        autopep8
        isort
      ]);

    shellHook = with nsf-py-nix-lib; with nsf-shc-nix-lib; ''
      ${nsfPy.shell.runSetuptoolsShellHook "${builtins.toString ./.}" default}
      ${nsfShC.shell.loadClickExesBashCompletion [
        "device-common-ssh-auth-dir"
        "device-ssh-auth-dir"
      ]}

      source ${shellHookLib}
      nsf_py_set_interpreter_env_from_path

      sh_hook_py_add_local_pkg_src_nixos_sf_test_lib
      sh_hook_py_add_local_pkg_src_nixos_sf_ssh_auth_cli
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
