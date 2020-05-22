{ stdenv
, lib
, makeWrapper
, coreutils
, gnugrep
, mr
, yq
, python3
, bashInteractive
, nsf-pin-cli
, nsf-shell-complete-nix-lib
, nixos-sf-factory-common-install
, nixos-sf-factory-install-py
}:

let

pythonLib = nixos-sf-factory-install-py;
pythonPkgs = with python3.pkgs; [
    pythonLib
  ];
pythonInterpreter = python3.withPackages (pp: pythonPkgs);

in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-sf-factory-install";
  name = "${pname}-${version}";


  src = ./.;

  nativeBuildInputs = [
    makeWrapper
    # Required as we have python shebangs that needs to be patched
    # with a python that has the proper libraries.
    pythonInterpreter
  ];

  propagatedUserEnvPkgs = [
    nixos-sf-factory-common-install
  ];

  propagatedBuildInputs = [
    mr
  ];

  buildInputs = [
    nsf-pin-cli
    nixos-sf-factory-common-install
    coreutils
    gnugrep
    mr # Simplifies working with multiple repos.
    yq
    pythonInterpreter
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-${pname}-get-sh-lib-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir/sh-lib' "$out/share/${pname}/sh-lib"

    substituteInPlace ./bin/pkg-${pname}-get-root-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir' "$out/share/${pname}"

    ! test -e "./.local-env.sh" || rm ./.local-env.sh
  '';

  buildPhase = "true";

  installPhase = with nsf-shell-complete-nix-lib; ''
    mkdir -p "$out/share/${pname}"
    find . -mindepth 1 -maxdepth 1 -exec mv -t "$out/share/${pname}" {} +

    mkdir -p "$out/bin"
    for cmd in $(find "$out/share/${pname}/bin" -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"
      makeWrapper "$cmd" "$out/bin/$target_cmd_basename" \
        --prefix PATH : "${stdenv.lib.makeBinPath buildInputs}" \
        --prefix PATH : "$out/share/${pname}/bin"
    done

    # Principally required for read -e -i 'Default value'
    # but also, we need to patch programs earlier as we
    # need to run some of these in order to produce bash
    # completions just below.
    PATH="${bashInteractive}/bin:$PATH" patchShebangs "$out"

    ${shComp.pkg.installClickExesBashCompletion [
      "device-common-ssh-auth-dir"
      "device-ssh-auth-dir"
    ]}
  '';

  meta = {
    description = ''
      Some scripts meant to be run by the factory technician
      to install nixos on new devices.
    '';
  };

  passthru = {
    inherit pname;
    python-interpreter = pythonInterpreter;
    python-packages = pythonPkgs;
    python-lib = pythonLib;
  };
}
