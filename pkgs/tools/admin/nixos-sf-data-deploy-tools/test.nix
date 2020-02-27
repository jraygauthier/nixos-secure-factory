{ pkgs ? import <nixpkgs> {} }:
with pkgs; rec {
  src = lib.sourceByRegex ./. [
      "^tests$"
      "^tests/installed$"
      "^tests/installed/.*\\.py$"
    ];
}