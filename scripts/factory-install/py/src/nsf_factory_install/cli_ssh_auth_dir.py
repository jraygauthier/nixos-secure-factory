import logging
import os
import sys
from typing import Optional

from nsf_factory_common_install.store_factory_info import \
    get_factory_info_user_id
from nsf_ssh_auth_dir.cli import CliInitCtx, run_cli

from .store_ssh_auth import (get_common_ssh_auth_dir_path,
                             get_device_specific_ssh_auth_dir_path)


def _get_prog_name() -> str:
    return os.path.basename(sys.argv[0] if sys.argv else __file__)


def _is_click_requesting_shell_completion():
    prog_name = _get_prog_name()

    complete_var = f"_{prog_name}_COMPLETE".replace("-", "_").upper()
    return os.environ.get(complete_var, None) is not None


def _fetch_user_id() -> Optional[str]:
    try:
        return get_factory_info_user_id()
    except FileNotFoundError as e:
        logging.warning(f"Cannot infer 'user_id': {str(e)}.")
        return None


def run_cli_common():
    if _is_click_requesting_shell_completion():
        return run_cli()

    init_ctx = CliInitCtx(
        cwd=get_common_ssh_auth_dir_path(),
        user_id=_fetch_user_id()
    )

    run_cli(init_ctx)


def run_cli_device_specific():
    if _is_click_requesting_shell_completion():
        return run_cli()

    init_ctx = CliInitCtx(
        cwd=get_device_specific_ssh_auth_dir_path(),
        user_id=_fetch_user_id()
    )

    run_cli(init_ctx)
