{ stdenv
, makeWrapper
, nixos-factory-common-install-scripts
, mr
, yq
, python3
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-factory-install";
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
    (python3.withPackages (pp: with pp; [
        pytest
        ipython
      ])
    )
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-${pname}-get-libexec-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir/libexec' "$out/share/${pname}/libexec"

    substituteInPlace ./bin/pkg-${pname}-get-root-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir' "$out/share/${pname}"

    ! test -e "./.local-env.sh" || rm ./.local-env.sh
  '';

  installPhase = ''
    mkdir -p "$out/share/${pname}"
    find . -mindepth 1 -maxdepth 1 -exec mv -t "$out/share/${pname}" {} +

    mkdir -p "$out/bin"
    for cmd in $(find "$out/share/${pname}/bin" -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"
      makeWrapper "$cmd" "$out/bin/$target_cmd_basename" \
        --prefix PATH : "${stdenv.lib.makeBinPath buildInputs}" \
        --prefix PATH : "$out/share/${pname}/bin"
    done
  '';

  meta = {
    description = ''
      Some scripts meant to be run by the factory technician
      to install nixos on new devices.
    '';
  };

}
