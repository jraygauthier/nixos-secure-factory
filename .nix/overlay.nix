{ srcs
, pickedSrcs
}:
self: super:

let
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

  nixos-sf-common = (import
    ../scripts/common/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-common-install = (import
    ../scripts/common-install/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-device-common-install = (import
    ../scripts/device-common-install/release.nix {
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

  # TODO: This shell hook lib should be factored out
  # into a separate external utility repository (e.g.: nsf-py).
  # Anyway, it has nothing factory install specific.
  nixos-sf-factory-common-install-py-shell-hook-lib = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).py-release.shell-hook-lib;

  nixos-sf-factory-install = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).default;

  nixos-sf-factory-install-py = (import
    ../scripts/factory-common-install/release.nix {
      pkgs = self;
    }).python-lib;
}
