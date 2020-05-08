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

  envLib = import ../../../lib/env.nix {
      inherit lib bash-completion;
    };

  nixos-sf-ssh-auth-cli-root-dir = ../../../pkgs/tools/admin/nixos-sf-ssh-auth;

  nixos-sf-ssh-auth-cli = (import
    (nixos-sf-ssh-auth-cli-root-dir + "/release.nix") {
      inherit pkgs;
    }).python-lib;

  nixos-sf-test-lib-root-dir = ../../../pkgs/development/python-modules/nixos-sf-test-lib;

  nixos-sf-test-lib = (import
    (nixos-sf-test-lib-root-dir + "/release.nix") {
      inherit pkgs;
    }).default;

  pythonPackages = pkgs.python3Packages;

  default = pythonPackages.callPackage ./. {
    inherit nixos-sf-ssh-auth-cli;
  };

  env = mkShell {
    name = "${default.pname}-env";

    buildInputs = [ default ];

    shellHook = ''
      ${envLib.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
      ${envLib.ensureDynamicBashCompletionLoaderInstalled}
    '';
  };

  python-packages = with pythonPackages; rec {
    common = default.propagatedBuildInputs ++ [
      default
    ];

    test-only = [
      pytest
      mypy
      flake8
    ];

    dev-only = [
      ipython
    ];

    test = common ++ test-only;
    dev = common ++ test-only ++ dev-only;
  };

  shellHookLib = writeShellScript "python-project-shell-hook-lib.sh" ''
      # TODO: Make this more concise while avoiding the vscode debugger issue
      # observed when using the bash colon trick.
      sh_hook_lib_prefix_path() {
        local varname="''${1?}"
        local -n old_value="''${1?}"
        local prefixed_value="''${2?}"
        if [[ -z "''${old_value}" ]]; then
          export "''${varname}=$prefixed_value"
        else
          export "''${varname}=$prefixed_value:''${old_value}"
        fi
      }

      sh_hook_py_set_interpreter_env() {
        python_interpreter="''${1?}"
        if ! [[ -e "$python_interpreter" ]]; then
          1>&2 echo "ERROR: ''${FUNCNAME[0]}: Cannot find expected " \
            "'$python_interpreter' python interpreter path."
          exit 1
        fi
        if [[ -d "$python_interpreter" ]] || ! [[ -x "$python_interpreter" ]]; then
          1>&2 echo "ERROR: ''${FUNCNAME[0]}: Specified python interpreter path " \
            "'$python_interpreter' does not refer to a executable program."
          exit 1
        fi

        export "PYTHON_INTERPRETER=$python_interpreter"
      }

      sh_hook_py_set_interpreter_env_from_path() {
        local python_interpreter
        python_interpreter="$(which python)"
        sh_hook_py_set_interpreter_env "$python_interpreter"
      }

      sh_hook_py_set_interpreter_env_from_nix_store_path() {
        local python_interpreter_nix_store_path="''${1?}"
        local python_interpreter="$python_interpreter_nix_store_path/bin/python"
        sh_hook_py_set_interpreter_env "$python_interpreter"
      }

      sh_hook_py_add_local_pkg_src_if_present() {
        local pkg_src_dir="''${1?}"
        if [[ -e "$pkg_src_dir" ]]; then
          sh_hook_lib_prefix_path "PYTHONPATH" "$pkg_src_dir"
          sh_hook_lib_prefix_path "MYPYPATH" "$pkg_src_dir"
        fi
      }

      sh_hook_lib_mypy_5701_workaround() {
        # Workaround for 'mypy/issues/5701'
        local pyton_nix_store_path="''${1?}"
        local pythonV
        pythonV="$(echo "$pyton_nix_store_path" \
          | awk -F/ '{ print $4 }' \
          | awk -F- '{ print $3}' \
          | awk -F. '{ printf "%s.%s", $1, $2 }')"

        local pythonSitePkgs="''${pyton_nix_store_path}/lib/python''${pythonV}/site-packages"

        if ! [[ -e "$pythonSitePkgs" ]]; then
          1>&2 echo "ERROR: ''${FUNCNAME[0]}: Cannot find expected " \
            "'$pythonSitePkgs' python site package path."
          exit 1
        fi

        sh_hook_lib_prefix_path "MYPYPATH" "''${pyton_nix_store_path}/lib/python''${pythonV}/site-packages"
      }

      sh_hook_lib_mypy_5701_workaround_from_path() {
        local pyton_nix_store_path
        pyton_nix_store_path="$(which python | xargs dirname | xargs dirname)"
        sh_hook_lib_mypy_5701_workaround "$pyton_nix_store_path"
      }

      sh_hook_py_add_local_pkg_src_nixos_sf_test_lib() {
        sh_hook_py_add_local_pkg_src_if_present \
          "${builtins.toString nixos-sf-test-lib-root-dir}/src"
      }

      sh_hook_py_add_local_pkg_src_nixos_sf_factory_common_install_py() {
        sh_hook_py_add_local_pkg_src_if_present \
          "${builtins.toString ./src}"
      }
  '';

  dev = default.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs
      ++ python-packages.test-only
      ++ python-packages.dev-only;

    shellHook = ''
      ${oldAttrs.shellHook}
      source ${shellHookLib}
      sh_hook_py_set_interpreter_env_from_path
      sh_hook_lib_mypy_5701_workaround_from_path
      sh_hook_py_add_local_pkg_src_nixos_sf_test_lib
    '';
  });
in

rec {
  inherit env default;

  shell = {
    dev = mkShell rec {
      name = "${default.pname}-dev-shell";
      inputsFrom = [dev];
    };
  };

  inherit python-packages;

  python-interpreter = {
    default = python3.withPackages (pp:
      python-packages.common);

    test = python3.withPackages (pp:
      python-packages.test);

    dev = python3.withPackages (pp:
      python-packages.dev);
  };

  nix-lib = {
    shell-hook-lib = shellHookLib;
  };
}
