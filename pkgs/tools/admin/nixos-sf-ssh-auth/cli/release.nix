{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs)
    callPackage
    python3Packages
    mkShell
    bash-completion;

  default = python3Packages.callPackage ./. {};
  defaultWDevTools = default.override {
      withDevTools = true;
    };

  env = mkShell {
    name = "${default.pname}-env";

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


in

rec {
  inherit env default;

  shell = {
    dev = mkShell rec {
      name = "${defaultWDevTools.pname}-build-shell";
      inputsFrom = [
        defaultWDevTools
      ];
    };
  };
}
