import click

from nsf_ssh_auth_dir.cli import CliCtx, init_cli_ctx
from nsf_ssh_auth_dir.cli import cli as cli_base

from ..store_ssh_auth import get_device_specific_ssh_auth_dir_path

from ._click import is_click_requesting_shell_completion
from ._factory_info import get_user_id


@click.group(cls=click.CommandCollection, sources=[cli_base])
@click.pass_context
def cli(ctx: click.Context) -> None:
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
    if is_click_requesting_shell_completion():
        return

    init_cli_ctx(ctx, CliCtx(
        cwd=get_device_specific_ssh_auth_dir_path(),
        user_id=get_user_id()
    ))


def run_cli() -> None:
    cli()
