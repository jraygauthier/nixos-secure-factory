{ stdenv
, makeWrapper
, nixos-common-install-scripts
, nixos-device-system-update
, openssh
, yq
, sshfs-fuse
, gnupg
, gopass
, screen
, socat
, picocom
, python3
, virtualbox
, mr
, xclip
, diffutils
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-factory-common-install-scripts";
  name = "${pname}-${version}";


  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedUserEnvPkgs = [
    nixos-common-install-scripts
    nixos-device-system-update
  ];

  propagatedBuildInputs = [
    mr
  ];

  buildInputs = [
    nixos-common-install-scripts
    nixos-device-system-update
    mr # Simplifies working with multiple repos.

    # TODO: Consider removing the openssh dep as the nix
    # version might not work on non-nixos.
    openssh # ssh, sftp, scp, ssh-keygen
    gnupg
    yq # yaml manipulations
    sshfs-fuse
    gopass

    screen
    socat
    picocom
    python3

    # TODO: Consider this. Not certain if nix would be capable
    # of introducing this dependency on non nix system as it
    # requires a setuid wrapper.
    # virtualbox

    xclip
    diffutils
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-nixos-factory-common-install-get-libexec-dir \
      --replace 'default_pkg_dir/libexec' 'default_pkg_dir/${pname}/libexec' \
  '';

  installPhase = ''
    mkdir -p "$out/${pname}/libexec"
    cp -p "./libexec/"* "$out/${pname}/libexec"

    for cmd in $(find ./bin -mindepth 1 -maxdepth 1); do
      cmd_basename="$(basename $cmd)"
      install -vD $cmd $out/bin/$cmd_basename;
      wrapProgram $out/bin/$cmd_basename \
        --prefix PATH : ${stdenv.lib.makeBinPath buildInputs}
    done
  '';

  meta = {
    description = ''
      Some scripts meant to be run by the factory technician
      to install nixos on new devices.
    '';
  };

}
