{ stdenv
, makeWrapper
, nixos-factory-common-install-scripts
, mr
, yq
, python3
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-factory-install-scripts";
  name = "${pname}-${version}";


  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  propagatedUserEnvPkgs = [
    nixos-factory-common-install-scripts
  ];

  propagatedBuildInputs = [
    mr
  ];

  buildInputs = [
    nixos-factory-common-install-scripts
    mr # Simplifies working with multiple repos.
    yq
    python3
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg_nixos_factory_install_get_libexec_dir \
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
