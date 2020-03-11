
import grp
import pwd

from typing import Set


def get_os_users() -> Set[str]:
    return set([u.pw_name for u in pwd.getpwall()])


def get_os_groups() -> Set[str]:
    return set([g.gr_name for g in grp.getgrall()])
