{ pkgs ? import <nixpkgs> {} } @ args:

(import ./release.nix args).shell.installed
