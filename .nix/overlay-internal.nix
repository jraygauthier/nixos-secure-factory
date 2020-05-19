{ srcs
, pickedSrcs
}:
self: super:

let
  nsf-pin = {
    inherit (import
      ./pkgs/tools/package-management/nsf-pin/release.nix
      { pkgs = self; })
    cli nix-lib;
  };
  nixos-sf-ssh-auth = {
    inherit (import
      ./pkgs/tools/admin/nixos-sf-ssh-auth/release.nix
      { pkgs = self; })
    cli python-lib nix-lib;
  };
in

{
  # Tag to check that our overlay is already available.
  has-overlay-nixos-secure-factory-internal = true;

  nsf-shell-complete-nix-lib = (import
    ./pkgs/build-support/nsf-shell-complete/release.nix
    { pkgs = self; }
    ).nix-lib;

  nixos-sf-ssh-auth-cli = nixos-sf-ssh-auth.cli;
  nixos-sf-ssh-auth-python-lib = nixos-sf-ssh-auth.python-lib;
  nixos-sf-ssh-auth-nix-lib = nixos-sf-ssh-auth.nix-lib;

  nsf-pin-cli = nsf-pin.cli;
  nsf-pin-nix-lib = nsf-pin.nix-lib;
}
