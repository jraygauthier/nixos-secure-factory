import ctypes
import grp
import os
import pwd
from typing import List, Set, Optional


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


def get_os_users() -> Set[str]:
    return set([u.pw_name for u in pwd.getpwall()])


def get_os_groups() -> Set[str]:
    return set([g.gr_name for g in  grp.getgrall()])


def touch_file(filename: str) -> None:
    with open(filename, "w") as f:
        pass


def write_file_content(filename: str, lines: List[str]) -> None:
    with open(filename, "w") as f:
        f.writelines(lines)


def change_file_permissions(
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


def format_file_permission(filename: str):
    if not os.path.exists(filename):
        return "mode: ??, uid: ??, gid: ??"

    mode = get_file_mode_simple(filename)
    uid = get_file_uid(filename)
    gid = get_file_gid(filename)

    return "mode: {}, uid: {}, gid: {}".format(oct(mode), uid, gid)
