import subprocess
from typing import List
from pathlib import Path

from .io import (
    _dict_to_shell_opts,
    _tuple_to_shell_opts,
    sanitize_shell_out_to_line_list,
)


def call_sh_module_fn(module_path: Path, fn_name: str, *args, **kwargs) -> List[str]:
    return sanitize_shell_out_to_line_list(subprocess.check_output([
        "bash", "-c",
        "set -euf -o pipefail; . {}; {} \"$@\"".format(module_path, fn_name),
        "--"
    ] + _tuple_to_shell_opts(args) + _dict_to_shell_opts(kwargs)
    ))
