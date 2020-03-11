import grp
import os
import pwd

from typing import Optional


def get_file_mode(filename: str) -> int:
    return os.stat(filename).st_mode


def get_file_mode_str(filename: str) -> str:
    return oct(get_file_mode(filename))


def get_file_mode_simple(filename: str) -> int:
    return get_file_mode(filename) & 0o000777


def get_file_mode_simple_str(filename: str) -> str:
    return oct(get_file_mode_simple(filename))


def get_file_uid(file: str) -> int:
    return os.stat(file).st_uid


def get_file_gid(file: str) -> int:
    return os.stat(file).st_gid


def get_file_owner(file: str) -> str:
    return pwd.getpwuid(get_file_uid(file)).pw_name


def get_file_group(file: str) -> str:
    return grp.getgrgid(get_file_gid(file)).gr_name


def change_file_mode_uid_gid(
        filename: str,
        mode: Optional[int] = None,
        uid: Optional[int] = None,
        gid: Optional[int] = None
) -> None:
    if mode is not None:
        os.chmod(filename, mode)

    need_chown = uid is not None or gid is not None

    if need_chown:
        uid = uid or get_file_uid(filename)
        gid = gid or get_file_gid(filename)
        os.chown(filename, uid, gid)
