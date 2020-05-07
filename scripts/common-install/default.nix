{ stdenv
, lib
, makeWrapper
, nixos-common-scripts
, coreutils
, gnugrep
, gnupg
, gopass
, git
, bashInteractive
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-sf-common-install";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];


  propagatedUserEnvPkgs = [
    nixos-common-scripts
  ];

  propagatedBuildInputs = [
    nixos-common-scripts
  ];

  buildInputs = [
    nixos-common-scripts
    coreutils
    gnugrep
    gnupg
    gopass
    git
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

  pythonPathDeps = lib.strings.makeSearchPath "python-lib" [
  ];

  binPathDeps = stdenv.lib.makeBinPath buildInputs;

  installPhase = ''
    mkdir -p "$out/share/${pname}"
    find . -mindepth 1 -maxdepth 1 -exec mv -t "$out/share/${pname}" {} +

    mkdir -p "$out/bin"
    for cmd in $(find "$out/share/${pname}/bin" -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"
      makeWrapper "$cmd" "$out/bin/$target_cmd_basename" \
        --prefix PATH : "${binPathDeps}" \
        --prefix PATH : "$out/share/${pname}/bin" \
        --prefix PYTHONPATH : "$out/share/${pname}/python-lib" \
        --prefix PYTHONPATH : "${pythonPathDeps}"
    done
  '';

  # Principally required for read -e -i 'Default value'.
  preFixup = ''
    PATH="${bashInteractive}/bin:$PATH" patchShebangs "$out"
  '';

  shellHook = ''
    export PATH="${src}/bin''${binPathDeps:+:}$binPathDeps''${PATH:+:}$PATH"
    export PYTHONPATH="${src}/python-lib''${pythonPathDeps:+:}$pythonPathDeps''${PYTHONPATH:+:}$PYTHONPATH"
  '';

  meta = {
    description = ''
      Some scripts meant to be run on both the nixos device and
      the factory install computer.
    '';
  };

}
