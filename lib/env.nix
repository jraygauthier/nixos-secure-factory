{ lib, bash-completion }:

{
  exportXdgDataDirsOf = xdgInputs: ''
    # Bring xdg data dirs of dependencies and current program into the
    # environement. This will allow us to get shell completion if any
    # and there might be other benefits as well.
    xdg_inputs=( ${lib.strings.concatStringsSep " " xdgInputs} )
    for p in "''${xdg_inputs[@]}"; do
      if [[ -d "$p/share" ]]; then
        XDG_DATA_DIRS="$p/share''${XDG_DATA_DIRS+:}''${XDG_DATA_DIRS}"
      fi
    done
    export XDG_DATA_DIRS
  '';

  ensureDynamicBashCompletionLoaderInstalled = ''
    # Make sure we support the pure case as well as non nixos cases
    # where dynamic bash completions were not sourced.
    if ! type _completion_loader > /dev/null; then
      . ${bash-completion}/etc/profile.d/bash_completion.sh
    fi
  '';
}