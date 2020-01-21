{ lib, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../../device-family/generic/nixos/configuration.nix
    ];

  virtualisation.virtualbox.guest.enable = true;
}