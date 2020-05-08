{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-common-install = (import
    ../common-install/release.nix {
      inherit pkgs;
    }).default;
  nixos-sf-device-system-config = (import
    ../device-system-config/release.nix {
      inherit pkgs;
    }).default;
  nixos-sf-device-system-config-updater = (import
    ../device-system-config-updater/release.nix {
      inherit pkgs;
    }).default;

  pyRelease = import
    ./py/release.nix {
      inherit pkgs;
    };

  devPython = pyRelease.python-interpreter.dev;
  defaultPython = pyRelease.python-interpreter.default;

  pyShellHookLib = pyRelease.nix-lib.shell-hook-lib;

  default = (callPackage ./. {
    inherit nixos-sf-common-install;
    inherit nixos-sf-device-system-config;
    inherit nixos-sf-device-system-config-updater;
    pythonLib = pyRelease.default;
    pythonInterpreter = defaultPython;
  } // {
    envShellHook = writeScript "envShellHook.sh" ''
    '';
  });

  env = buildEnv {
    name = "${default.pname}-build-env";
    paths = [ default ];
  };

  envLib = import ../../lib/env.nix {
    inherit lib bash-completion;
  };
in

rec {
  inherit default env;

  shell = {
    build = mkShell rec {
      name = "${default.pname}-build-shell";
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

      shellHook = ''
        source "${default.envShellHook}"

        ${envLib.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
        ${envLib.ensureDynamicBashCompletionLoaderInstalled}

        shell_dir="${toString ./.}"
        test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

        export "PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
        . "$shell_dir/env.sh"

        export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_IN_ENV=1
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

      shellHook = ''
        shell_dir="${toString ./.}"
        test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

        export "PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
        . "$shell_dir/env.sh"

        export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_IN_BUILD_ENV=1

        export PATH="${builtins.toString ./bin}:$PATH"

        source ${pyShellHookLib}
        sh_hook_py_set_interpreter_env_from_nix_store_path "${devPython}"
        sh_hook_lib_mypy_5701_workaround "${devPython}"
        sh_hook_py_add_local_pkg_src_nixos_sf_test_lib
        sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py
      '';
    };
  };

  python-lib = pyRelease.default;
}
