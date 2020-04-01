from pathlib import Path
from nsft_system_utils.permissions import (
    FilePermissions,
    get_file_permissions,
)


def check_has_expected_permissions(
        in_file: Path, expected: FilePermissions) -> None:
    actual = get_file_permissions(in_file)
    assert expected.mode_simple == actual.mode_simple
    assert expected.uid == actual.uid
    assert expected.gid == actual.gid
