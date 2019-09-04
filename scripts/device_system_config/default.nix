{ stdenv
, makeWrapper
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-system-config-scripts";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-nixos-device-system-config-get-libexec-dir \
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
      Some scripts to help with the updating of a nixos device.
    '';
  };
}
