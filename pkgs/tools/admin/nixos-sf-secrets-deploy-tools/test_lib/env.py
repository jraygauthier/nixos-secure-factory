import shutil
from nsft_shell_utils import has_admin_priviledges
from nsft_system_utils import get_os_users, get_os_groups


def is_package_installed() -> bool:
    return shutil.which("pkg-nixos-sf-secrets-deploy-tools-get-sh-lib-dir") is not None


def are_package_propagated_dependencies_installed() -> bool:
    return shutil.which("pkg-nixos-sf-data-deploy-tools-get-sh-lib-dir") is not None


def from_nixos_test_machine() -> bool:
    return (
        has_admin_priviledges()
        and "nsft-other-user" in get_os_users()
        and "nsft-other-group" in get_os_groups()
        and "nsft-yet-another-user" in get_os_users()
        and "nsft-yet-another-group" in get_os_groups()
    )
