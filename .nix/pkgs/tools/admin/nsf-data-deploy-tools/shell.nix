{ nixpkgs ? null
, pkgs ? import (if null != nixpkgs then nixpkgs else <nixpkgs>) {} } @ args:

(import ./release.nix args).shell.dev
