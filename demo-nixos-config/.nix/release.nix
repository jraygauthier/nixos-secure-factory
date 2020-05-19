{ pkgs ? import (import ./default.nix {}).nixpkgs {}  # Can be set `null`.
, workspaceDir ? builtins.toString ../..
}:

import ./default.nix { inherit pkgs workspaceDir; }
