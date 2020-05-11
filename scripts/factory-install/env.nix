{ pkgs ? import ../../pkgs/pinned/nixpkgs.nix {} } @ args:

(import ./release.nix args).shell.installed
