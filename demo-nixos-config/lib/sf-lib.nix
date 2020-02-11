{ workspaceDir ? null }:

let
  sfSrc = import ./sf.nix { inherit workspaceDir; };
  sfLibSrc = sfSrc + "/lib";
  sfLib = import (sfLibSrc + "/default.nix") {};
in

sfLib
