{ srcs
, pickedSrcs
}:
self: super:

let
  nsf-pin = import "${pickedSrcs.nsf-pin.src}/release.nix" {
    pkgs = self;
  };

  nsf-py = import "${pickedSrcs.nsf-py.src}/release.nix" {
    pkgs = self;
  };

  nsf-shc = import "${pickedSrcs.nsf-shc.src}/release.nix" {
    pkgs = self;
  };

  nsf-ssh-auth = import "${pickedSrcs.nsf-ssh-auth.src}/release.nix" {
    pkgs = self;
  };
in

{
  # **IMPORTANT**: In order too prevent these our dependencies're
  # own `release.nix` module to append their overlays to the package set,
  # we want to make sure that our internal overlay is a strict
  # superset of theirs.
  # See `nixos-secure-factory/.nix/overlay-internal.nix`.
  # TOOD: Automated check for this that at least raise a warning.
  nsf-pin-cli = nsf-pin.cli;
  nsf-pin-nix-lib = nsf-pin.nix-lib;

  nsf-py-nix-lib = nsf-py.nix-lib;

  nsf-shc-nix-lib = nsf-shc.nix-lib;

  nsf-ssh-auth-cli = nsf-ssh-auth.cli;
  nsf-ssh-auth-nix-lib = nsf-ssh-auth.nix-lib;
}
