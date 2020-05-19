{ lib
, stdenv
, nix-gitignore
, gnused
, dieHook
, coreutils
, bash
}:

let
  mkBinPathPrefixStr = xs: "export PATH=\"${lib.makeBinPath xs}\"\${PATH:+\":\"}$PATH";
  runtimeDeps = [ coreutils ];
in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-sf-data-deploy-tools";
  name = "${pname}-${version}";

  shLibInstallDir = "${placeholder "out"}/share/${pname}/sh-lib";

  src = nix-gitignore.gitignoreSourcePure [
    ../../../../../.gitignore
    "*.nix\n"
    ] ./.;

  nativeBuildInputs = [ gnused dieHook ];
  buildInputs = runtimeDeps;

  buildPhase = ":";

  installPhase = ''
    mkdir -p "${shLibInstallDir}"
    for f in $(find ./sh-lib -mindepth 1 -maxdepth 1); do
      target_file_basename="$(basename "$f")"
      sed -E \
        "$f" \
        -e 's#^(sh_lib_dir)=.+$#\1="${shLibInstallDir}"#g' \
        > "${shLibInstallDir}/$target_file_basename"
    done

    mkdir -p "$out/bin"

    for cmd in $(find ./bin -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"

      # Ensure that input has required format.
      grep -q -E -e '^#!.+bash$' "$cmd" || die "Bad input." \
        || die "Missing bash shebang in input."
      grep -q -E -e '^sh_lib_dir=.+$' "$cmd" \
        || die "Missing 'sh_lib_dir' variable assignment in input."

      # Instead of using the provided wrapper helpers,
      # patch the input file.
      sed -E \
        "$cmd" \
        -e '/^#!.+bash$/a ${mkBinPathPrefixStr runtimeDeps}' \
        -e 's#^(sh_lib_dir)=.+$#\1="${shLibInstallDir}"#g' \
        > "$out/bin/$target_cmd_basename"
      chmod a+x "$out/bin/$target_cmd_basename"
    done
  '';

  passthru = {
    inherit pname version name;
  };

  meta = {
    description = ''
      Some basic data deploy tools meant to be used as part of the
      nixos-sf-data-deploy framework.
    '';
  };
}
