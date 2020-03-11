import logging
import os
import subprocess
from typing import Optional

import pytest
from nsft_shell_utils import call_shell_program
from nsft_system_utils import (change_file_mode_uid_gid, format_file_permission,
                               get_file_gid,
                               get_file_mode_simple,
                               get_file_uid)

from test_lib.env import (are_package_propagated_dependencies_installed,
                          from_nixos_test_machine, is_package_installed)

LOGGER = logging.getLogger(__name__)


# pytestmark = pytest.mark.skipif(not is_package_installed(), reason="Package programs not found in PATH!")

mark_only_for_nixos_test_machine = pytest.mark.skipif(
    not from_nixos_test_machine(),
    reason="Only reproducible on controlled test machine."
)


def test_package_installed():
    assert is_package_installed()


def test_propagated_dependencies_installed():
    assert are_package_propagated_dependencies_installed()


def test_get_sh_lib_dir():
    lines = call_shell_program("pkg-nixos-sf-secrets-deploy-tools-get-sh-lib-dir")
    assert lines
    dir_path = lines[0]
    assert os.path.exists(dir_path)

    sh_module_path = os.path.join(dir_path, "deploy-tools.sh")
    assert os.path.exists(sh_module_path)


from dataclasses import dataclass
from typing import Tuple, Union


@dataclass
class ExpShellOutcome:
    status: int
    stdout_re: Optional[str] = None
    stderr_re: Optional[str] = None


ExpShellOutcomeTupleT = Tuple[int, Optional[str], Optional[str]]
ExpShellOutcomeClassTupleOrIntT = Union[ExpShellOutcome, ExpShellOutcomeTupleT, int]


def mk_exp_shell_outcome(
        in_value: ExpShellOutcomeClassTupleOrIntT
) -> ExpShellOutcome:
    if isinstance(in_value, ExpShellOutcome):
        return in_value
    if isinstance(in_value, int):
        return ExpShellOutcome(in_value)

    return ExpShellOutcome(*in_value)


@dataclass
class ExpShellOutcomeByContext:
    unprivileged: ExpShellOutcome
    privileged: ExpShellOutcome


ExpShellOutcomeByContextTupleT = Tuple[
    ExpShellOutcomeClassTupleOrIntT, ExpShellOutcomeClassTupleOrIntT]
ExpShellOutcomeByContextClassOrTupleT = Union[
    ExpShellOutcomeByContext, ExpShellOutcomeByContextTupleT]


def mk_exp_shell_outcome_by_context(
        in_value: ExpShellOutcomeByContextClassOrTupleT
) -> ExpShellOutcomeByContext:
    if isinstance(in_value, ExpShellOutcomeByContext):
        return in_value

    return ExpShellOutcomeByContext(
        *map(mk_exp_shell_outcome, in_value))


def expecting_success(expected_outcome: ExpShellOutcomeByContextClassOrTupleT):
    exp_outcome = mk_exp_shell_outcome_by_context(expected_outcome)
    if from_nixos_test_machine():
        return 0 != exp_outcome.privileged.status
    else:
        return 0 != exp_outcome.unprivileged.status





def check_has_expected_permissions(
        in_file: str, expected: FilePermissions) -> None:
    actual = get_file_permissions(in_file)
    assert expected.mode == actual.mode
    assert expected.uid == actual.uid
    assert expected.gid == actual.gid



"""
("dummy.txt", None, None, None), # Allow clobber non ro target file
("dir1/tgt.txt", None, None, None),
("dir2/dir/tgt.txt", None, None, None),
("dir3/dir/tgt.txt", 0o0755, None, None),
pytest.param(
    "dir4/dir/tgt.txt", 0o0600, None, None,
    marks=mark_only_for_nixos_test_machine
),
pytest.param(
    "dir5/dir/tgt.txt", None, 1020, 1050,
    marks=mark_only_for_nixos_test_machine
),
pytest.param(
    "dir6/dir/tgt.txt", 0o0444, 1021, 1051,
    marks=mark_only_for_nixos_test_machine
),
"""

@pytest.mark.parametrize(
    "rel_src_file, rel_tgt_file, expected_outcome, inherited_permissions", [
    ("dummy.txt", "tgt.txt", (0, 0), (None, None, None))
])
def test_pgp_file_deploy_w_inherited_permissions(
        src_tmp_dir_w_dummy_files, tgt_tmp_dir_w_dummy_files,
        rel_src_file, rel_tgt_file, expected_outcome, inherited_permissions) -> None:

    expected_outcome = mk_exp_shell_outcome_by_context(expected_outcome)
    inherited_permissions = ensure_file_permissions_opt(inherited_permissions)

    src_tmp_dir = src_tmp_dir_w_dummy_files
    src_file = os.path.join(src_tmp_dir, rel_tgt_file)
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files
    tgt_file = os.path.join(tgt_tmp_dir, rel_tgt_file)

    LOGGER.info("src_file: %s", src_file)
    LOGGER.info("tgt_file: %s", tgt_file)

    change_file_permissions(tgt_tmp_dir, inherited_permissions)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    exp_permissions = ensure_file_permissions_w_ref(inherited_permissions, tgt_tmp_dir)

    def call_program():
        call_shell_program(
            "nsf-pgp-file-deploy-w-inherited-permissions", src_file, tgt_file)

    if not expecting_success(expected_outcome):
        with pytest.raises(subprocess.CalledProcessError) as e:
            call_program()
        assert 1 == e.value.returncode
        assert not os.path.exists(tgt_file)
        return

    call_program()

    assert os.path.exists(tgt_file)
    LOGGER.info("tgt_file permissions: {%s}", format_file_permission(tgt_file))

    check_has_expected_permissions(tgt_file, exp_permissions)



