{ device_identifier
, device_system_config_dir
, workspaceDir ? null
, nixpkgs ? import <nixpkgs> {}
# TODO: No longer needed. Deprecated. Remove at some point.
, device_system_config_src_dir ? null
}:

let
  nixos-sf-device-system-config-updater =
    import ../scripts/device-system-config-updater/release.nix
      { inherit nixpkgs; };
in

nixpkgs.callPackage ./. {
  inherit device_identifier device_system_config_dir;
  inherit nixos-sf-device-system-config-updater;
}
