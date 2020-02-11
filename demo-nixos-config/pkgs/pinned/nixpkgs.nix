{}:

let
  pinnedNixpkgsSrc = (import ../pinned-src/nixpkgs/default.nix {}).default.src;
  pinnedPkgs = import pinnedNixpkgsSrc {};
in
  pinnedPkgs
