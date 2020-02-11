{ stdenv
, lib
, makeWrapper
, jq
, nixos-sf-device-system-config-updater
, device_identifier
, device_system_config_dir
}:

let
  # systemConfigPkg = nixos-device-system-config;
  systemConfigDir = device_system_config_dir;
  # TODO: Retrieve this from wrapped package instead.
  systemConfigEtcCfgDirName = "nixos-device-system-config";

  updateBuildAndInstallExe = "${nixos-sf-device-system-config-updater}/bin/nixos-sf-device-system-config-update-build-and-install";
in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-system-config-dir-update";
  name = "${pname}-${version}";

  src = ./.;

  pkgCfgDir = "etc/${pname}";

  nativeBuildInputs = [
    makeWrapper
    jq
  ];

  buildInputs = [
    # systemConfigPkg
    nixos-sf-device-system-config-updater
  ];

  installPhase = ''
    # Make sure the updater package contain the expected binaries.
    if ! test -x "${updateBuildAndInstallExe}"; then
      1>&2 echo "ERROR: cannot find updater build and install executable at expected location: "
      1>&2 echo "  '${updateBuildAndInstallExe}'."
      return 1
    fi

    mkdir -p "$out/etc"
    # TODO: Should we copy instead?
    ln -s -T "${systemConfigDir}/etc/${systemConfigEtcCfgDirName}" "$out/etc/${systemConfigEtcCfgDirName}"

    mkdir -p "$out/${pkgCfgDir}"
    mkdir -p "$out/bin"

    cat << 'EOF' > "$out/bin/current-system-config-update-build-and-install"
    #! ${stdenv.shell}
    action="''${1:-boot}"
    ${updateBuildAndInstallExe} "${device_system_config_dir}" "$action"
    EOF

    chmod a+x "$out/bin/current-system-config-update-build-and-install"
  '';

  meta = {
    description = ''
      Wrap a specific device configuration with its custom update scripts.
    '';
  };
}
