{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  nixos-sf-factory-common-install = (import
    ../factory-common-install/release.nix {
      inherit pkgs;
    }).default;

  default = callPackage ./. {
      inherit nixos-sf-factory-common-install;
    };
in

{
  default = (default // {
      envShellHook = writeScript "envShellHook.sh" ''
        source "${nixos-sf-factory-common-install.envShellHook}"
      '';
    });
}