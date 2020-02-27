import os
import subprocess

from typing import List, Any, Dict

def sanitize_shell_out_to_line_list(shell_output: bytes) -> List[str]:
    return shell_output.decode("utf-8").rstrip().splitlines()


def _list_to_shell_opts(in_list: List[Any]) -> List[str]:
    out = []
    for v in in_list:
        # assert isinstance(v, str)
        out.append(str(v))
    return out


def _dict_to_shell_opts(in_dict: Dict[str, Any]) -> List[str]:
    out = []
    for k, v in in_dict.items():
        if 1 < len(k):
            out.append("--{}".format(k))
        else:
            out.append("-{}".format(k))

        if v is not None:
            # assert isinstance(v, str)
            out.append(str(v))

    return out


def call_shell_program(shell_program: str, *args, **kwargs) -> List[str]:
    return sanitize_shell_out_to_line_list(subprocess.check_output([
        shell_program
    ]
    + _list_to_shell_opts(args)
    + _dict_to_shell_opts(kwargs)
    ))


def call_sh_module_fn(module_path: str, fn_name: str, *args, **kwargs) -> List[str]:
    return sanitize_shell_out_to_line_list(subprocess.check_output([
        "bash", "-c",
        "set -euf -o pipefail; . {}; {} \"$@\"".format(module_path, fn_name),
        "--"
    ]
    + _list_to_shell_opts(args)
    + _dict_to_shell_opts(kwargs)
    ))


def has_admin_priviledges() -> bool:
    try:
        return 0 == os.getuid()
    except AttributeError:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
