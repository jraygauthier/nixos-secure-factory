import os
from dataclasses import dataclass
from typing import Optional, Tuple, Union

from .permissions_simple import (
    change_file_mode_uid_gid,
    get_file_gid,
    get_file_mode,
    get_file_uid,
)


@dataclass
class FilePermissionsOpt:
    mode: Optional[int]
    uid: Optional[int]
    gid: Optional[int]


FilePermissionsOptTupleT = Tuple[Optional[int], Optional[int], Optional[int]]
FilePermissionsOptOrTupleT = Union[FilePermissionsOpt, FilePermissionsOptTupleT]


@dataclass
class FilePermissions:
    mode: int
    uid: int
    gid: int

    @property
    def mode_simple(self) -> int:
        return self.mode & 0o000777


FilePermissionsClassOptOrTupleT = Union[FilePermissions, FilePermissionsOptOrTupleT]


def ensure_file_permissions_opt(
        in_value: FilePermissionsOptOrTupleT) -> FilePermissionsOpt:
    if isinstance(in_value, FilePermissionsOpt):
        return in_value

    return FilePermissionsOpt(*in_value)


def ensure_file_permissions_w_ref(
        in_value: FilePermissionsClassOptOrTupleT, ref_file: str) -> FilePermissions:
    if isinstance(in_value, FilePermissions):
        return in_value

    if isinstance(in_value, FilePermissionsOpt):
        return FilePermissions(
            in_value.mode or get_file_mode(ref_file),
            in_value.uid or get_file_uid(ref_file),
            in_value.gid or get_file_gid(ref_file)
        )

    return ensure_file_permissions_w_ref(
        FilePermissionsOpt(*in_value), ref_file)


def change_file_permissions(
        in_file: str, permissions: FilePermissionsOptOrTupleT) -> None:
    permissions = ensure_file_permissions_opt(permissions)
    change_file_mode_uid_gid(
        in_file,
        permissions.mode, permissions.uid, permissions.gid
    )


def get_file_permissions(in_file: str) -> FilePermissions:
    return FilePermissions(
        get_file_mode(in_file),
        get_file_uid(in_file),
        get_file_gid(in_file)
    )


def format_file_permission(filename: str):
    if not os.path.exists(filename):
        return "mode: ??, uid: ??, gid: ??"

    mode = get_file_mode(filename)
    uid = get_file_uid(filename)
    gid = get_file_gid(filename)

    return "mode: {}, uid: {}, gid: {}".format(oct(mode), uid, gid)
