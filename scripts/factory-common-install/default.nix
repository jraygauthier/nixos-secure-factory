{ stdenv
, lib
, makeWrapper
, coreutils
, gnugrep
, nixos-sf-shell-complete-nix-lib
, nixos-sf-common-install
, nixos-sf-device-system-config
, nixos-sf-device-system-config-updater
, openssh
, yq
, jq
, sshfs-fuse
, pwgen
, mkpasswd
, screen
, socat
, picocom
, python3
, virtualbox
, mr
, xclip
, diffutils
, bashInteractive
, nix-prefetch-git
, nix-prefetch-github
, tightvnc
, nixos-sf-factory-common-install-py
}:

let

pythonLib = nixos-sf-factory-common-install-py;
pythonPkgs = with python3.pkgs; [
    pythonLib
  ];
pythonInterpreter = python3.withPackages (pp: pythonPkgs);

in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-sf-factory-common-install";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
    # Required as we have python shebangs that needs to be patched
    # with a python that has the proper libraries.
    pythonInterpreter
  ];

  propagatedUserEnvPkgs = [
    nixos-sf-common-install
    nixos-sf-device-system-config
  ];

  propagatedBuildInputs = [
    mr
    nixos-sf-common-install
    nixos-sf-device-system-config
  ];

  buildInputs = [
    nixos-sf-common-install
    nixos-sf-device-system-config
    coreutils
    gnugrep
    mr # Simplifies working with multiple repos.

    # TODO: Consider removing the openssh dep as the nix
    # version might not work on non-nixos.
    openssh # ssh, sftp, scp, ssh-keygen
    yq # yaml manipulations
    jq # json manipulations
    sshfs-fuse
    pwgen
    mkpasswd

    tightvnc # provide vncviewer
    screen
    socat
    picocom
    pythonInterpreter

    # TODO: Consider this. Not certain if nix would be capable
    # of introducing this dependency on non nix system as it
    # requires a setuid wrapper.
    # virtualbox

    xclip
    diffutils

    nix-prefetch-git
    nix-prefetch-github

    nixos-sf-device-system-config-updater
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


  binPathDeps = stdenv.lib.makeBinPath buildInputs;

  buildPhase = "true";

  installPhase = with nixos-sf-shell-complete-nix-lib; ''
    mkdir -p "$out/share/${pname}"
    find . -mindepth 1 -maxdepth 1 -exec mv -t "$out/share/${pname}" {} +

    mkdir -p "$out/bin"
    for cmd in $(find "$out/share/${pname}/bin" -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"
      makeWrapper "$cmd" "$out/bin/$target_cmd_basename" \
        --prefix PATH : "${binPathDeps}" \
        --prefix PATH : "$out/share/${pname}/bin"
    done

    # Principally required for read -e -i 'Default value'
    # but also, we need to patch programs earlier as we
    # need to run some of these in order to produce bash
    # completions just below.
    PATH="${bashInteractive}/bin:$PATH" patchShebangs "$out"

    ${shComp.pkg.installClickExesBashCompletion [
      "device-state-checkout"
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
