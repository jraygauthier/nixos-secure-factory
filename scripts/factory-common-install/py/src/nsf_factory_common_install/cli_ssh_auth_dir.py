import logging
import click
import os
import sys
from typing import Optional

from nsf_factory_common_install.store_factory_info import \
    get_factory_info_user_id
from nsf_ssh_auth_dir.cli import CliCtx, cli, init_cli_ctx

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


@click.group(cls=click.CommandCollection, sources=[cli])
@click.pass_context
def cli_common(ctx: click.Context):
    """Ssh authorization tool for nixos-secure-factory projects.

    Operates on the *core-cfg*'s **common** *auth-dir*.
    That is, the set of authorizations shared by all devices.

    You can get more information about the target authorization
    directory using the `info` sub-command.

    Note that it remains **you responsability** to add / commit /
    push your changes to *version control*. We however provide
    some `git` helpers under `[cmd] git`.
    """
    if _is_click_requesting_shell_completion():
        return

    init_cli_ctx(ctx, CliCtx(
        cwd=get_common_ssh_auth_dir_path(),
        user_id=_fetch_user_id()
    ))

# cli_common = click.make_pass_decorator


def run_cli_common() -> None:
    cli_common()


@click.group(cls=click.CommandCollection, sources=[cli])
@click.pass_context
def cli_device_specific(ctx: click.Context):
    """Ssh authorization tool for nixos-secure-factory projects.

    Operates on the *core-cfg*'s **device-specific** *auth-dir*.
    That is, the set of authorizations given to a particular
    devices (by default the current device).

    You can get more information about the target directory
    using the `[cmd] info` command.

    Note that it remains **you responsability** to add / commit /
    push your changes to *version control*. We however provide
    some `git` helpers under `[cmd] git`.
    """
    if _is_click_requesting_shell_completion():
        return

    init_cli_ctx(ctx, CliCtx(
        cwd=get_device_specific_ssh_auth_dir_path(),
        user_id=_fetch_user_id()
    ))


def run_cli_device_specific() -> None:
    cli_device_specific()
