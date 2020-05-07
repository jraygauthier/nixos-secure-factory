{ stdenv
, lib
, nix-gitignore
, writeTextFile
, deviceIdentifier
, extraNixSearchPath
, deviceInfoJsonPath
, nixpkgsSrc
, nixpkgs
, nixos-secure-factory
}:

let
  # Use the provided json file if available. Otherwise, fallback on
  # the internally kept file (most likely a test / developer device).
  deviceInfoJson = if deviceInfoJsonPath != null
    then deviceInfoJsonPath
    else ./. + "/device/${deviceIdentifier}/device.json";
  deviceInfo = builtins.fromJSON (builtins.readFile deviceInfoJson);
  deviceType = deviceInfo.type;
  deviceId = deviceInfo.identifier;

  nixos_src = nixpkgsSrc;

  nixSearchPath = extraNixSearchPath // {
    nixpkgs = nixpkgsSrc;
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
          ${if builtins.pathExists (./. + "/device/${deviceId}/nixos/configuration.nix")
          then ''
            ./device/${deviceId}/nixos/configuration.nix
          ''
          else ""
          }
        ];

      system.nixosSecureFactoryDevice.identifier = "${deviceId}";
      system.nixosSecureFactoryDevice.type = "${deviceType}";
    }
  '';};

  etcCfgDirName = "nixos-device-system-config";

in

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-sf-device-system-config-dir";
  name = "${pname}-${version}";

  pkgCfgDir = "etc/${etcCfgDirName}";
  nixSearchPathDir = "${pkgCfgDir}/nix-search-path";

  src = nix-gitignore.gitignoreSourcePure ../.gitignore ./.;

  postPatch = ''
    mkdir -p "./device/${deviceId}"
    cp "${deviceInfoJson}" "device/${deviceId}/device.json"
  '';

  buildInputs = [
  ];

  installPhase = ''
    mkdir -p "$out/${pkgCfgDir}"
    mkdir -p "$out/${pkgCfgDir}/device"
    mkdir -p "$out/${nixSearchPathDir}"

    cp -R -t "$out/${pkgCfgDir}/device" "./device/${deviceId}"

    ln -s -T "$out/${pkgCfgDir}/device/${deviceId}" "$out/${pkgCfgDir}/current-device"

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

