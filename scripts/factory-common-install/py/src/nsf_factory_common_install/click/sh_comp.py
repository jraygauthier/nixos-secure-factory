import os
import sys


def _get_prog_name() -> str:
    return os.path.basename(sys.argv[0] if sys.argv else __file__)


def is_click_requesting_shell_completion():
    prog_name = _get_prog_name()

    complete_var = f"_{prog_name}_COMPLETE".replace("-", "_").upper()
    return os.environ.get(complete_var, None) is not None
