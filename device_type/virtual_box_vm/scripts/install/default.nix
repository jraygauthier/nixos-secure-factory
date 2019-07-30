{ stdenv
, nixos-device-common-install-scripts
, makeWrapper
, gnugrep
, usbutils
, procps
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-type-install-scripts";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedUserEnvPkgs = [
    nixos-device-common-install-scripts
  ];

  propagatedBuildInputs = [
    nixos-device-common-install-scripts
  ];

  buildInputs = [
    nixos-device-common-install-scripts
    # For the common lib *.sh.
    gnugrep
    usbutils
    procps
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg_nixos_device_type_install_get_libexec_dir \
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
      Some scripts meant to be run on new nixos devices of a specific type when
      first installed.
    '';
  };

}
