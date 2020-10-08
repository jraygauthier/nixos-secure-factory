{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.nixosDeviceSystemConfigUpdater;
  nsf-device-system-config-updater = (import
    ../../../scripts/device-system-config-updater/release.nix
      {
        inherit pkgs;
        # TODO: Consider the pros / cons of doing this.
        # nix = config.nix.package.out;
      }).default;

  defaultChannelOptions = {
    options = {
      type = mkOption {
        type = types.enum [ "git" ];
        example = "git";
        description = ''
          The default channel / url type.
        '';
      };

      url = mkOption {
        type = types.str;
        example = "git@bitbucket.org:my-org/my-repo.git";
        description = ''
          The default url from which to retrieve system configuration updates.
        '';
      };
      ref = mkOption {
        type = types.str;
        example = "stable";
        default = "master";
        description = ''
          For a channel based a repository (e.g.: git), the default branch or
          tag to be checked out. If no <literal>ref</literal> nor
          <literal>rev</literal> specified, "master" will be used.
        '';
      };
      rev = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "e47eb72a2adece3da337fca1a9d14bc8cda79b52";
        description = ''
          For a channel based a repository (e.g.: git), the default specific
          revision (e.g.: git sha) to be checked out. Has priority over
          <literal>ref</literal>.
        '';
      };

      # TODO: Constraint to either ref or rev.
    };
  };

in

{

  options = {

    system.nixosDeviceSystemConfigUpdater = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to periodically upgrade the NixOS device system configuration
          to the latest version. If enabled, a systemd timer will run
          <literal>nixos-rebuild switch --upgrade</literal> once a day.
        '';
      };

      deviceIdentifier = mkOption {
        type = types.nullOr types.str;
        example = "my_device_identifier";
        description = ''
          The device identifier that will be used to retrieve device
          specific configuration and device specific secrets during
          system updates.

          The update system expects the config directory to contain
          at its root a subdirectory named <literal>device</literal>
          which will hold a per device json configuration at:
          <literal>./device/my_device_identifier/device.json</literal>
          and might also hold a device specific updater configuration
          at: <literal>./device/my_device_identifier/updater-config</literal>
          which might be used to specify a device specific channel.

          The update system also expects the device secret vault repository to
          contain a sub directory named <literal>device</literal> which will
          hold per device secrets
          <literal>./device/my_device_identifier/my_device_specific_secret</literal>.
        '';
      };

      systemConfigDefaultChannel = mkOption {
        type = types.submodule defaultChannelOptions;
        # TODO: Example.
        # example =
        description = ''
          The default channel used to retrieve system configuration updates. When
          <literal>null</literal>, <literal>systemConfigDefaultChannel</literal>
          values will be used.
        '';
      };

      dates = mkOption {
        default = "04:40";
        example = "minutely";
        type = types.str;
        description = ''
          Specification (in the format described by
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>) of the time at
          which the update will occur.
        '';
      };

    };

  };

  config = {
    systemd.services.nsf-device-system-config-updater = {
      description = "NixOS Device System Config Updater";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";
      serviceConfig.SyslogIdentifier = "nsf-device-system-config-updater";

      environment = config.nix.envVars //
        { inherit (config.environment.sessionVariables) NIX_PATH;
          HOME = "/root";
        } // config.networking.proxy.envVars;

      path = [
      ];

      script = ''
        #  nix-collect-garbage --delete-old
        ${nsf-device-system-config-updater}/bin/nsf-device-system-config-update
      '';

      startAt = optional cfg.enable cfg.dates;
    };

    environment.systemPackages = [
      nsf-device-system-config-updater
    ];

    environment.etc."nsf-device-system-config-updater/config-defaults.yaml" =
      let
        systemUpdaterEtcConfigDir = "nsf-device-system-config-updater";
        systemUpdaterDefaults = {
          device-identifier = cfg.deviceIdentifier;
          channel = {
            system-config = if cfg.systemConfigDefaultChannel.rev == null
              then  {
                type = cfg.systemConfigDefaultChannel.type;
                url = cfg.systemConfigDefaultChannel.url;
                ref = cfg.systemConfigDefaultChannel.ref;
              } else {
                type = cfg.systemConfigDefaultChannel.type;
                url = cfg.systemConfigDefaultChannel.url;
                rev = cfg.systemConfigDefaultChannel.rev;
              };
          };
        };

        systemUpdaterDefaultsJsonFile = pkgs.writeText "config-defaults.json" (
          builtins.toJSON systemUpdaterDefaults);

        systemUpdaterConfigDefaults = pkgs.stdenv.mkDerivation rec {
          version = "0.1.0";
          pname = "nsf-device-system-config-updater-config-defaults";
          name = "${pname}-${version}";

          src = ./.;

          nativeBuildInputs = [
            pkgs.yq
          ];

          buildInputs = [
          ];

          installPhase = ''
            mkdir -p "$out/etc/${systemUpdaterEtcConfigDir}"
            cat "${systemUpdaterDefaultsJsonFile}" | yq -y '.' > "$out/etc/${systemUpdaterEtcConfigDir}/config-defaults.yaml"
          '';

        };
      in
    {
      mode = "0600";
      text = lib.fileContents "${systemUpdaterConfigDefaults}/etc/${systemUpdaterEtcConfigDir}/config-defaults.yaml";
    };
  };
}
