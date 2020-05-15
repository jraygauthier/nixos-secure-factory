import logging
import os
import subprocess
import pytest

from pathlib import Path
from typing import Optional

from nsft_shell_utils.program import call_shell_program
from nsft_system_utils.permissions_simple import (change_file_mode_uid_gid,
                                                  get_file_gid,
                                                  get_file_mode_simple,
                                                  get_file_mode_str, get_file_uid)

from nsft_system_utils.permissions import format_file_permission

from test_lib.env import is_package_installed, from_nixos_test_machine

LOGGER = logging.getLogger(__name__)

_OptMode = Optional[int]
_OptUID = Optional[int]
_OptGID = Optional[int]


pytestmark = pytest.mark.skipif(
    not is_package_installed(),
    reason="Package programs not found in PATH!")


mark_only_for_nixos_test_machine = pytest.mark.skipif(
    not from_nixos_test_machine(),
    reason="Only reproducible on controlled test machine."
)


def test_get_sh_lib_dir() -> None:
    lines = call_shell_program("pkg-nixos-sf-data-deploy-tools-get-sh-lib-dir")
    assert lines
    dir_path = lines[0]
    assert os.path.exists(dir_path)

    sh_module_path = os.path.join(dir_path, "deploy-tools.sh")
    assert os.path.exists(sh_module_path)


@pytest.mark.parametrize("mode_str", [
    (""),
    ("bob"),
])
def test_change_mode_invalid(
        dummy_tgt_file: Path, mode_str: str) -> None:
    tgt_file = dummy_tgt_file
    LOGGER.info("tgt_file: %s", tgt_file)

    previous_mode = get_file_mode_simple(tgt_file)
    expected_mode = previous_mode

    with pytest.raises(subprocess.CalledProcessError) as e:
        call_shell_program("nsf-file-chmod", tgt_file, mode_str)

    assert 1 == e.value.returncode
    assert expected_mode == get_file_mode_simple(tgt_file)


@pytest.mark.parametrize("mode_str, expected_mode", [
    ("a-w", 0o0444),
    ("0600", 0o0600),
])
def test_change_mode(
        dummy_tgt_file: Path, mode_str: str, expected_mode: int) -> None:
    tgt_file = dummy_tgt_file
    LOGGER.info("tgt_file: %s", tgt_file)

    LOGGER.info("previous st_mode: %s", get_file_mode_str(tgt_file))

    call_shell_program("nsf-file-chmod", tgt_file, mode_str)

    assert expected_mode == get_file_mode_simple(tgt_file)

    LOGGER.info("new st_mode: %s", get_file_mode_str(tgt_file))


@pytest.mark.parametrize("owner_str, group_str", [
    ("nsft-invalid-user", "nsft-invalid-group"),
])
def test_change_owner_invalid(
        dummy_tgt_file: Path, owner_str: str, group_str: str) -> None:
    tgt_file = dummy_tgt_file
    LOGGER.info("tgt_file: %s", tgt_file)

    previous_uid = get_file_uid(tgt_file)
    previous_gid = get_file_gid(tgt_file)

    with pytest.raises(subprocess.CalledProcessError) as e:
        call_shell_program("nsf-file-chown", tgt_file, owner_str, group_str)

    assert 1 == e.value.returncode

    new_uid = get_file_uid(tgt_file)
    new_gid = get_file_gid(tgt_file)

    assert previous_uid == new_uid
    assert previous_gid == new_gid


@mark_only_for_nixos_test_machine
@pytest.mark.parametrize("owner_str, group_str, expected_uid, expected_gid", [
    ("", "", None, None),
    ("nsft-other-user", "nsft-other-group", 1020, 1050),
    ("1021", "", 1021, None),
    ("", "nsft-yet-another-group", None, 1051),
    ("nsft-yet-another-user", 1050, 1021, 1050)
])
def test_change_owner(
        dummy_tgt_file: Path, owner_str: str, group_str: str,
        expected_uid: _OptUID, expected_gid: _OptGID):
    tgt_file = dummy_tgt_file
    previous_uid = get_file_uid(tgt_file)
    previous_gid = get_file_gid(tgt_file)
    if expected_uid is None:
        expected_uid = previous_uid
    if expected_gid is None:
        expected_gid = previous_gid

    LOGGER.info("tgt_file: %s", tgt_file)
    LOGGER.info("previous_uid: %s", previous_uid)
    LOGGER.info("previous_gid: %s", previous_gid)

    call_shell_program("nsf-file-chown", tgt_file, owner_str, group_str)

    new_uid = get_file_uid(tgt_file)
    new_gid = get_file_gid(tgt_file)

    LOGGER.info("new_uid: %s", new_uid)
    LOGGER.info("new_gid: %s", new_gid)

    assert expected_uid == new_uid
    assert expected_gid == new_gid


@pytest.mark.parametrize(
    ("rel_src_file, rel_tgt_file, priviledged_ok, inherited_mode, "
     "inherited_uid, inherited_gid"), [
        ("dummy.txt", "dummy-dir-ro/tgt.txt", True, None, None, None),
        ("does-not-exists.txt", "tgt.txt", False, None, None, None),
        ("dummy.txt", "dummy-ro.txt", True, None, None, None),
    ])
def test_deploy_file_w_inherited_permissions_invalid(
        src_tmp_dir_w_dummy_files: Path, tgt_tmp_dir_w_dummy_files: Path,
        rel_src_file: str, rel_tgt_file: str, priviledged_ok: bool,
        inherited_mode: _OptMode,
        inherited_uid: _OptUID, inherited_gid: _OptGID) -> None:

    src_tmp_dir = src_tmp_dir_w_dummy_files
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files

    src_file = src_tmp_dir.joinpath(rel_src_file)
    tgt_file = tgt_tmp_dir.joinpath(rel_tgt_file)

    LOGGER.info("src_file: %s", src_file)
    LOGGER.info("tgt_file: %s", tgt_file)

    change_file_mode_uid_gid(
        tgt_tmp_dir, inherited_mode, inherited_uid, inherited_gid)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    if priviledged_ok and from_nixos_test_machine():
        call_shell_program(
            "nsf-file-deploy-w-inherited-permissions", src_file, tgt_file)
        assert os.path.exists(tgt_file)
    else:
        with pytest.raises(subprocess.CalledProcessError) as e:
            call_shell_program(
                "nsf-file-deploy-w-inherited-permissions", src_file, tgt_file)

        assert 1 == e.value.returncode


@pytest.mark.parametrize("rel_tgt_file, inherited_mode, inherited_uid, inherited_gid", [
    ("tgt.txt", None, None, None),
    ("dummy.txt", None, None, None),  # Allow clobber non ro target file
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
])
def test_deploy_file_w_inherited_permissions(
        dummy_src_file: Path, tgt_tmp_dir_w_dummy_files: Path,
        rel_tgt_file: str, inherited_mode: _OptMode,
        inherited_uid: _OptUID, inherited_gid: _OptGID) -> None:
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files
    tgt_file = tgt_tmp_dir.joinpath(rel_tgt_file)
    LOGGER.info("tgt_file: %s", tgt_file)

    change_file_mode_uid_gid(
        tgt_tmp_dir, inherited_mode, inherited_uid, inherited_gid)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    expected_mode = inherited_mode or get_file_mode_simple(tgt_tmp_dir)
    expected_uid = inherited_uid or get_file_uid(tgt_tmp_dir)
    expected_gid = inherited_gid or get_file_gid(tgt_tmp_dir)

    call_shell_program(
        "nsf-file-deploy-w-inherited-permissions", dummy_src_file, tgt_file)

    LOGGER.info("tgt_file permissions: {%s}", format_file_permission(tgt_file))

    assert os.path.exists(tgt_file)
    assert expected_mode == get_file_mode_simple(tgt_file)
    assert expected_uid == get_file_uid(tgt_file)
    assert expected_gid == get_file_gid(tgt_file)


@pytest.mark.parametrize(
    "rel_tgt_dir, priviledged_ok, inherited_mode, inherited_uid, inherited_gid", [
        # TODO: Consider clobbering existing file.
        ("dummy.txt", False, None, None, None),  # Over an existing file.
        ("dummy-ro.txt", False, None, None, None),  # Over an existing ro file.
        ("dummy-dir-ro/tgt-dir", True, None, None, None),  # Under a ro dir.
    ])
def test_mkdir_w_inherited_permissions_invalid(
        tgt_tmp_dir_w_dummy_files: Path, rel_tgt_dir: str,
        priviledged_ok: bool,
        inherited_mode: _OptMode, inherited_uid: _OptUID, inherited_gid: _OptGID
) -> None:
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files
    tgt_dir = tgt_tmp_dir.joinpath(rel_tgt_dir)
    LOGGER.info("tgt_dir: %s", tgt_dir)

    change_file_mode_uid_gid(
        tgt_tmp_dir, inherited_mode, inherited_uid, inherited_gid)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    if priviledged_ok and from_nixos_test_machine():
        call_shell_program("nsf-dir-mk-w-inherited-permissions", tgt_dir)
        assert os.path.exists(tgt_dir)
    else:
        with pytest.raises(subprocess.CalledProcessError) as e:
            call_shell_program("nsf-dir-mk-w-inherited-permissions", tgt_dir)

        assert 1 == e.value.returncode


@pytest.mark.parametrize(
    "rel_tgt_dir, inherited_mode, inherited_uid, inherited_gid", [
        ("tgt-dir", None, None, None),
        ("dummy-dir", None, None, None),  # Allow existing dir
        ("dummy-dir-ro", None, None, None),  # Allow existing ro dir
        ("dir1/tgt-dir", None, None, None),
        ("dir2/dir/tgt-dir", None, None, None),
        ("dir3/dir/tgt-dir", 0o0755, None, None),
        pytest.param(
            "dir4/dir/tgt-dir", 0o0600, None, None,
            marks=mark_only_for_nixos_test_machine
        ),
        pytest.param(
            "dir5/dir/tgt-dir", None, 1020, 1050,
            marks=mark_only_for_nixos_test_machine
        ),
        pytest.param(
            "dir6/dir/tgt-dir", 0o0444, 1021, 1051,
            marks=mark_only_for_nixos_test_machine
        ),
    ])
def test_mkdir_w_inherited_permissions(
        tgt_tmp_dir_w_dummy_files: Path,
        rel_tgt_dir: str,
        inherited_mode: _OptMode, inherited_uid: _OptUID, inherited_gid: _OptGID
) -> None:
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files
    tgt_dir = tgt_tmp_dir.joinpath(rel_tgt_dir)
    LOGGER.info("tgt_dir: %s", tgt_dir)

    change_file_mode_uid_gid(
        tgt_tmp_dir, inherited_mode, inherited_uid, inherited_gid)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    ref_dir = tgt_tmp_dir
    if os.path.exists(tgt_dir):
        # When the directory already exists, it should be taken as the
        # reference for permissions.
        ref_dir = tgt_dir

    expected_mode = inherited_mode or get_file_mode_simple(ref_dir)
    expected_uid = inherited_uid or get_file_uid(ref_dir)
    expected_gid = inherited_gid or get_file_gid(ref_dir)

    call_shell_program("nsf-dir-mk-w-inherited-permissions", tgt_dir)

    LOGGER.info("tgt_dir permissions: {%s}", format_file_permission(tgt_dir))

    assert os.path.exists(tgt_dir)
    assert expected_mode == get_file_mode_simple(tgt_dir)
    assert expected_uid == get_file_uid(tgt_dir)
    assert expected_gid == get_file_gid(tgt_dir)


@pytest.mark.parametrize(
    "rel_tgt_file, unprivileged_ok, privileged_ok", [
        ("dummy.txt", True, True),
        ("dummy-ro.txt", True, True),  # The unprivileged_ok is surprising here.
        ("dummy-dir", False, False),
        ("dummy-dir-ro", False, False),
    ])
def test_rm_file(
        tgt_tmp_dir_w_dummy_files: Path,
        rel_tgt_file: str,
        unprivileged_ok: bool, privileged_ok: bool) -> None:
    tgt_tmp_dir = tgt_tmp_dir_w_dummy_files
    tgt_file = tgt_tmp_dir.joinpath(rel_tgt_file)
    LOGGER.info("tgt_file: %s", tgt_file)

    if from_nixos_test_machine():
        expecting_sucess = privileged_ok
    else:
        expecting_sucess = unprivileged_ok

    if expecting_sucess:
        call_shell_program("nsf-file-rm", tgt_file)
        assert not os.path.exists(tgt_file)
    else:
        with pytest.raises(subprocess.CalledProcessError) as e:
            call_shell_program("nsf-file-rm", tgt_file)

        assert 1 == e.value.returncode
        assert os.path.exists(tgt_file)
