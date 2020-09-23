{ srcs
, pickedSrcs
}:
self: super:

let
  nsf-data-deploy = {
    nix-lib = (import
      ./pkgs/tools/admin/nsf-data-deploy/release.nix
      { pkgs = self; }
      ).nix-lib;
    tools = (import
      ./pkgs/tools/admin/nsf-data-deploy-tools/release.nix
      { pkgs = self; }
      ).default;
  };

  nsf-secrets-deploy = {
    nix-lib = (import
      ./pkgs/tools/admin/nsf-secrets-deploy/release.nix
      { pkgs = self; }
      ).nix-lib;
    tools = (import
      ./pkgs/tools/admin/nsf-secrets-deploy-tools/release.nix
      { pkgs = self; }
      ).default;
  };
in

{
  # Tag to check that our overlay is already available.
  has-overlay-nixos-secure-factory = true;

  nsf-test-lib = (import
    ./pkgs/development/python-modules/nsf-test-lib/release.nix
    { pkgs = self; }
    ).default;

  nsf-deploy-core-nix-lib = (import
    ./pkgs/tools/admin/nsf-deploy-core/release.nix
    { pkgs = self; }
    ).nix-lib;

  nsf-data-deploy-nix-lib = nsf-data-deploy.nix-lib;
  nsf-data-deploy-tools = nsf-data-deploy.tools;

  nsf-secrets-deploy-nix-lib = nsf-secrets-deploy.nix-lib;
  nsf-secrets-deploy-tools = nsf-secrets-deploy.tools;

  nsf-common = (import
    ../scripts/common/release.nix {
      pkgs = self;
    }).default;

  nsf-common-install = (import
    ../scripts/common-install/release.nix {
      pkgs = self;
    }).default;

  nsf-device-common-install = (import
    ../scripts/device-common-install/release.nix {
      pkgs = self;
    }).default;

  nsf-device-system-config = (import
    ../scripts/device-system-config/release.nix {
      pkgs = self;
    }).default;

  nsf-device-system-config-updater = (import
    ../scripts/device-system-config-updater/release.nix {
      pkgs = self;
    }).default;

  nsf-factory-common-install = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).default;

  nsf-factory-common-install-py = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).python-lib;

  # TODO: This shell hook lib should be factored out
  # into a separate external utility repository (e.g.: nsf-py).
  # Anyway, it has nothing factory install specific.
  nsf-factory-common-install-py-shell-hook-lib = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).py-release.shell-hook-lib;

  nsf-factory-install = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).default;

  nsf-factory-install-py = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).python-lib;
}
