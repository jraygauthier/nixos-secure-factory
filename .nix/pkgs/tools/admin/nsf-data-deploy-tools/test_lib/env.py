import shutil
from nsft_shell_utils.permissions import has_admin_priviledges
from nsft_system_utils.os import get_os_groups, get_os_users


def is_package_installed():
    return shutil.which("pkg-nsf-data-deploy-tools-get-sh-lib-dir") is not None


def from_nixos_test_machine():
    return (
        has_admin_priviledges()
        and "nsft-other-user" in get_os_users()
        and "nsft-other-group" in get_os_groups()
        and "nsft-yet-another-user" in get_os_users()
        and "nsft-yet-another-group" in get_os_groups()
    )
