import os
import subprocess
from dataclasses import dataclass
from typing import Optional, Tuple, Union
from pathlib import Path

from .permissions_simple import (
    change_file_mode_uid_gid,
    get_file_gid,
    get_file_mode,
    get_file_uid,
)


@dataclass
class FilePermissionsOpts:
    mode: Optional[int] = None
    uid: Optional[int] = None
    gid: Optional[int] = None


FilePermissionsOptsTupleT = Tuple[Optional[int], Optional[int], Optional[int]]
FilePermissionsOptsSoftT = Union[FilePermissionsOpts, FilePermissionsOptsTupleT, None]


@dataclass
class FilePermissions:
    mode: int
    uid: int
    gid: int

    @property
    def mode_simple(self) -> int:
        return self.mode & 0o000777


FilePermissionsSoftT = Union[FilePermissions, FilePermissionsOptsSoftT]


def ensure_file_permissions_opt(
        in_value: FilePermissionsOptsSoftT) -> FilePermissionsOpts:
    if isinstance(in_value, FilePermissionsOpts):
        return in_value

    if in_value is None:
        return FilePermissionsOpts(None, None, None)

    return FilePermissionsOpts(*in_value)


def ensure_file_permissions_w_ref(
        in_value: FilePermissionsSoftT, ref_file: Path) -> FilePermissions:
    assert ref_file.exists()

    if isinstance(in_value, FilePermissions):
        return in_value

    in_value = ensure_file_permissions_opt(in_value)
    assert isinstance(in_value, FilePermissionsOpts)

    return FilePermissions(
        in_value.mode or get_file_mode(ref_file),
        in_value.uid or get_file_uid(ref_file),
        in_value.gid or get_file_gid(ref_file)
    )


def change_file_permissions(
        in_file: Path, permissions: FilePermissionsOptsSoftT) -> None:
    permissions = ensure_file_permissions_opt(permissions)
    change_file_mode_uid_gid(
        in_file,
        permissions.mode, permissions.uid, permissions.gid
    )


def call_chmod(
        in_file: Path,
        mode: Optional[str],
        recursive: bool = False,
        reference: Optional[Path] = None) -> None:
    assert in_file.exists()
    assert not (mode is not None and reference is not None)

    args = [
        "chmod"
    ]

    if recursive:
        args.append("-R")

    if mode is not None:
        args.append(mode)
    else:
        assert reference is not None
        args.extend([
            "--reference", f"{reference}"
        ])

    args.append(str(in_file))

    subprocess.check_output(args)


def get_file_permissions(in_file: Path) -> FilePermissions:
    return FilePermissions(
        get_file_mode(in_file),
        get_file_uid(in_file),
        get_file_gid(in_file)
    )


def format_file_permission(filename: Path):
    if not os.path.exists(filename):
        return "mode: ??, uid: ??, gid: ??"

    mode = get_file_mode(filename)
    uid = get_file_uid(filename)
    gid = get_file_gid(filename)

    return "mode: {}, uid: {}, gid: {}".format(oct(mode), uid, gid)
