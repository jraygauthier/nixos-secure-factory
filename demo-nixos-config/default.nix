{ stdenv
, lib
, nix-gitignore
, writeTextFile
, device_identifier
, extra_nix_search_path
, device_info_json_file
, nixpkgs_src
, nixpkgs
, nixos-secure-factory
}:

let
  # Use the provided json file if available. Otherwise, fallback on
  # the internally kept file (most likely a test / developer device).
  deviceInfoJson = if device_info_json_file != null
    then device_info_json_file
    else ./. + "/device/${device_identifier}/device.json";
  deviceInfo = builtins.fromJSON (builtins.readFile deviceInfoJson);
  deviceType = deviceInfo.type;
  deviceIdentifier = deviceInfo.identifier;

  nixos_src = nixpkgs_src;

  nixSearchPath = extra_nix_search_path // {
    nixpkgs = nixpkgs_src;
    nixos = nixos_src;
    inherit nixos-secure-factory;
  };

  configurationGenerated = writeTextFile { name = "configuration_generated.nix"; text = ''
    { lib, config, pkgs, ... }:
    {
      imports =
        [
          ./nixos/modules/system/etc/nixos-secure-factory-device.nix
          ./device-type/${deviceType}/nixos/configuration.nix
          ${if builtins.pathExists (./. + "/device/${deviceIdentifier}/nixos/configuration.nix")
          then ''
            ./device/${deviceIdentifier}/nixos/configuration.nix
          ''
          else ""
          }
        ];

      system.nixosSecureFactoryDevice.identifier = "${deviceIdentifier}";
      system.nixosSecureFactoryDevice.type = "${deviceType}";
    }
  '';};

  etcCfgDirName = "nixos-device-system-config";

in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-system-config-dir";
  name = "${pname}-${version}";

  pkgCfgDir = "etc/${etcCfgDirName}";
  nixSearchPathDir = "${pkgCfgDir}/nix-search-path";

  src = nix-gitignore.gitignoreSourcePure ../.gitignore ./.;

  postPatch = ''
    mkdir -p "./device/${deviceIdentifier}"
    cp "${deviceInfoJson}" "device/${deviceIdentifier}/device.json"
  '';

  buildInputs = [
  ];

  installPhase = ''
    mkdir -p "$out/${pkgCfgDir}"
    mkdir -p "$out/${pkgCfgDir}/device"
    mkdir -p "$out/${nixSearchPathDir}"

    cp -R -t "$out/${pkgCfgDir}/device" "./device/${deviceIdentifier}"

    ln -s -T "$out/${pkgCfgDir}/device" "$out/${pkgCfgDir}/current-device"

    # The files usually found along the configuration in a nixos-sf project.
    config_std_deps=( \
      "device-family" \
      "device-type" \
      "device-ssh" \
      "device-update" \
      "nixos" \
      "pkgs" \
      "lib" \
    )

    for in_f in "''${config_std_deps[@]}"; do
      if ! [[ -e "$in_f" ]]; then
        continue
      fi
      cp -R -t "$out/${pkgCfgDir}" "$in_f"
    done

    cp "${configurationGenerated}" "$out/${pkgCfgDir}/configuration.nix"
    ${lib.strings.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (n: v:
      ''
      ln -s -T "${v}" "$out/${nixSearchPathDir}/${n}"
      '') nixSearchPath)}
  '';

  meta = {
    description = ''
      Builds a specific device configuration.
    '';
  };
}

