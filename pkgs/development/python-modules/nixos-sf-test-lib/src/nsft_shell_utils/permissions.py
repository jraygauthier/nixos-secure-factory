import os


def has_admin_priviledges() -> bool:
    # try:
    return 0 == os.getuid()
    # except AttributeError:
    #     return ctypes.windll.shell32.IsUserAnAdmin() != 0
