{ lib
, buildPythonPackage
, mypy
, pytest
, flake8
, ipython
, click
, pyyaml
}:

buildPythonPackage rec  {
  pname = "nixos-sf-ssh-auth-cli";
  version = "0.0.0";
  src = ./.;
  buildInputs = [];

  doCheck = false;

  checkInputs = [
    mypy
    pytest
    flake8
  ];

  checkPhase = ''
    mypy .
    pytest .
    flake8
  '';

  propagatedBuildInputs = [
    click
    pyyaml
  ];

  postInstall = ''
    click_exes=( "nixos-sf-ssh-auth-dir" )

    # Install click application bash completions.
    bash_completion_dir="$out/share/bash-completion/completions"
    mkdir -p "$bash_completion_dir"
    for e in "''${click_exes[@]}"; do
      click_exe_path="$out/bin/$e"
      click_complete_env_var_name="_$(echo "$e" | tr "[a-z-]" "[A-Z_]")_COMPLETE"
      # TODO: For some reason, running this return a non zero (1) status code. This might
      # be a click library bug. Fill one if so.
      env "''${click_complete_env_var_name}=source_bash" "$click_exe_path" > "$bash_completion_dir/$e" || true
      # Because of the above, check that we got some completion code in the file.
      cat "$bash_completion_dir/$e" | grep "$e" > /dev/null
    done
  '';

  # Allow nix-shell inside nix-shell.
  # See `pkgs/development/interpreters/python/hooks/setuptools-build-hook.sh`
  # for the reason why.
  shellHook = ''
    setuptoolsShellHook
  '';
}
