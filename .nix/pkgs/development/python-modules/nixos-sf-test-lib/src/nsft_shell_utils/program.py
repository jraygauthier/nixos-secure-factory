import subprocess
from typing import List

from .io import (
    _dict_to_shell_opts,
    _tuple_to_shell_opts,
    sanitize_shell_out_to_line_list,
)


def call_shell_program(shell_program: str, *args, **kwargs) -> List[str]:
    return sanitize_shell_out_to_line_list(subprocess.check_output([
        shell_program
    ] + _tuple_to_shell_opts(args) + _dict_to_shell_opts(kwargs)
    ))
