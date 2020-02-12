{ lib, config, pkgs, ... }:

let
  sshAuthLib = import ../../../lib/ssh-auth.nix { inherit lib; };
  inherit (sshAuthLib) getUserKeyFileFromPerUserAuthKeys;
  perUserAuthKeysJsonFile = ../../../device-ssh/authorized/per-user-authorized-keys.json;
  perUserAuthKeys =
    let
      errMsg = ''
        Missing '${builtins.toString perUserAuthKeysJsonFile}' file.
        Please authorize at least one user access to the
        device configuration using 'device-os-config-ssh-authorize'.
      '';
    in
    assert builtins.pathExists perUserAuthKeysJsonFile || builtins.trace errMsg true;
    builtins.fromJSON (builtins.readFile perUserAuthKeysJsonFile);

  allUsersAuthKeyFiles = getUserKeyFileFromPerUserAuthKeys "" perUserAuthKeys;
  rootAuthKeyFiles = allUsersAuthKeyFiles ++ getUserKeyFileFromPerUserAuthKeys "root" perUserAuthKeys;
in

{
  imports =
    [
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = false;

  fileSystems."/boot" =
    {
      label = "boot";
      fsType = "vfat";
    };

  fileSystems."/" =
    {
      label = "nixos";
      fsType = "ext4";
    };

  swapDevices =
    [ {
        label = "swap";
      }
    ];

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.permitRootLogin = "prohibit-password";

  i18n = {
    consoleKeyMap = "cf"; # Canadian french
    defaultLocale = "en_CA.UTF-8";
  };

  users = {

    mutableUsers = false;

    extraUsers = {
      root = {
        openssh.authorizedKeys.keyFiles = rootAuthKeyFiles;
      };
    };
  };
}