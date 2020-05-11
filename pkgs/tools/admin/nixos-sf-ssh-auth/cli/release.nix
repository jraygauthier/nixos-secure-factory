{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs)
    callPackage
    python3Packages
    mkShell
    bash-completion
    writeShellScript;

  pythonPackages = python3Packages;

  default = pythonPackages.callPackage ./. {};

  shellHookLib = writeShellScript "python-project-shell-hook-lib.sh" ''
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

    shellHook = ''
      ${oldAttrs.shellHook}
      source ${shellHookLib}
      sh_hook_py_set_interpreter_env_from_path
    '';
  });

in

rec {
  inherit default;

  shell = {
    installed = mkShell {
      name = "${default.pname}-installed-shell";

      buildInputs = [ default ];

      shellHook = ''
        # Bring xdg data dirs of dependencies and current program into the
        # environement. This will allow us to get shell completion if any
        # and there might be other benefits as well.
        xdg_inputs=( "''${buildInputs[@]}" )
        for p in "''${xdg_inputs[@]}"; do
          if [[ -d "$p/share" ]]; then
            XDG_DATA_DIRS="''${XDG_DATA_DIRS}''${XDG_DATA_DIRS+:}$p/share"
          fi
        done
        export XDG_DATA_DIRS

        # Make sure we support the pure case as well as non nixos cases
        # where dynamic bash completions were not sourced.
        if ! type _completion_loader > /dev/null; then
          . ${bash-completion}/etc/profile.d/bash_completion.sh
        fi
      '';
    };

    dev = mkShell rec {
      name = "${default.pname}-build-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [
        dev
      ];
    };
  };
}
