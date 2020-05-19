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

  nixos-sf-data-deploy = {
    nix-lib = (import
      ./pkgs/tools/admin/nixos-sf-data-deploy/release.nix
      { pkgs = self; }
      ).nix-lib;
    tools = (import
      ./pkgs/tools/admin/nixos-sf-data-deploy-tools/release.nix
      { pkgs = self; }
      ).default;
  };

  nixos-sf-secrets-deploy = {
    nix-lib = (import
      ./pkgs/tools/admin/nixos-sf-secrets-deploy/release.nix
      { pkgs = self; }
      ).nix-lib;
    tools = (import
      ./pkgs/tools/admin/nixos-sf-secrets-deploy-tools/release.nix
      { pkgs = self; }
      ).default;
  };
in

{
  # Tag to check that our overlay is already available.
  has-overlay-nixos-secure-factory = true;

  nsf-shell-complete-nix-lib = (import
    ./pkgs/build-support/nsf-shell-complete/release.nix
    { pkgs = self; }
    ).nix-lib;

  nixos-sf-test-lib = (import
    ./pkgs/development/python-modules/nixos-sf-test-lib/release.nix
    { pkgs = self; }
    ).default;

  nixos-sf-deploy-core-nix-lib = (import
    ./pkgs/tools/admin/nixos-sf-deploy-core/release.nix
    { pkgs = self; }
    ).nix-lib;

  nixos-sf-data-deploy-nix-lib = nixos-sf-data-deploy.nix-lib;
  nixos-sf-data-deploy-tools = nixos-sf-data-deploy.tools;

  nixos-sf-secrets-deploy-nix-lib = nixos-sf-secrets-deploy.nix-lib;
  nixos-sf-secrets-deploy-tools = nixos-sf-secrets-deploy.tools;

  nixos-sf-ssh-auth-cli = nixos-sf-ssh-auth.cli;
  nixos-sf-ssh-auth-python-lib = nixos-sf-ssh-auth.python-lib;
  nixos-sf-ssh-auth-nix-lib = nixos-sf-ssh-auth.nix-lib;

  nsf-pin-cli = nsf-pin.cli;
  nsf-pin-nix-lib = nsf-pin.nix-lib;

  nixos-sf-common = (import
    ../scripts/common/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-common-install = (import
    ../scripts/common-install/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-device-system-config = (import
    ../scripts/device-system-config/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-device-system-config-updater = (import
    ../scripts/device-system-config-updater/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-factory-common-install = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-factory-common-install-py = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).python-lib;

  nixos-sf-factory-install = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-factory-install-py = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).python-lib;
}
