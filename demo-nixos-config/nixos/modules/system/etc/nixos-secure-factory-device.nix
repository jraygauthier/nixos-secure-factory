{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    system.nixosSecureFactoryDevice = {
      identifier = mkOption {
        type = types.str;
        example = "my_device_identifier";
        description = ''
          The identifier of the current device.

          Should be used by nix configurations to perform device
          specific operations.
        '';
      };

      type = mkOption {
        type = types.str;
        example = "my_device_type";
        description = ''
          The type of the current device.

          Should be used by nix configurations to perform device type
          specific operations.
        '';
      };
    };

  };
}
