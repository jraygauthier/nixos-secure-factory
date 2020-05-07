{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-ssh-auth-cli = (import
    ../../pkgs/tools/admin/nixos-sf-ssh-auth/release.nix {
      inherit pkgs;
    }).cli;

  nixos-sf-factory-common-install-py = (import
    ./py/release.nix {
      inherit pkgs;
    }).default;

  nixos-sf-common-install = (import
    ../common-install/release.nix {
      inherit pkgs;
    }).default;
  nixos-sf-device-system-config = (import
    ../device-system-config/release.nix {
      inherit pkgs;
    }).default;
  nixos-sf-device-system-config-updater = (import
    ../device-system-config-updater/release.nix {
      inherit pkgs;
    }).default;
  default = callPackage ./. {
    inherit nixos-sf-common-install;
    inherit nixos-sf-device-system-config;
    inherit nixos-sf-device-system-config-updater;
    inherit nixos-sf-ssh-auth-cli;
    inherit nixos-sf-factory-common-install-py;
  };

in

{
  default = (default // {
      envShellHook = writeScript "envShellHook.sh" ''
      '';
    });

  python-lib = nixos-sf-factory-common-install-py;
}