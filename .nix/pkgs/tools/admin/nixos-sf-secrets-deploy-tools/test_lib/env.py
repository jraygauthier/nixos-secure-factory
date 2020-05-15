import shutil

from nsft_shell_utils.outcome import (
    ExpShOutcome,
    ExpShOutcomeByCtxSoftT,
    ensure_exp_shell_outcome_by_context,
)
from nsft_shell_utils.permissions import has_admin_priviledges
from nsft_system_utils.os import get_os_groups, get_os_users


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


def get_current_ctx_outcome(
        expected_outcome: ExpShOutcomeByCtxSoftT) -> ExpShOutcome:
    exp_outcome = ensure_exp_shell_outcome_by_context(expected_outcome)
    if from_nixos_test_machine():
        return exp_outcome.privileged
    else:
        return exp_outcome.unprivileged
