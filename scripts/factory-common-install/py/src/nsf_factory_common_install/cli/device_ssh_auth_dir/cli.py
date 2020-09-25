from typing import Optional

import click

from nsf_factory_common_install.repo_project import (
    mk_project_repo,
)
from nsf_ssh_auth_dir.cli import CliCtx
from nsf_ssh_auth_dir.cli import cli as cli_base
from nsf_ssh_auth_dir.cli import init_cli_ctx

from nsf_factory_common_install.cli.click import is_click_requesting_shell_completion
from nsf_factory_common_install.cli.options import (
    cli_default_device_option,
    cli_default_user_option,
    ensure_user_id_or_user_factory_user_id,
    ensure_device_cfg_repo_device_by_id_or_current
)


@click.group(cls=click.CommandCollection, sources=[cli_base])
@cli_default_user_option()
@cli_default_device_option()
@click.pass_context
def cli(
        ctx: click.Context,
        user_id: Optional[str],
        device_id: Optional[str]
) -> None:
    """Ssh authorization tool for nixos-secure-factory projects.

    Operates on the *cfg*'s **device-specific** *auth-dir*.
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

    project = mk_project_repo()

    device_instance = ensure_device_cfg_repo_device_by_id_or_current(device_id, project)
    user_id = ensure_user_id_or_user_factory_user_id(user_id, project)

    init_cli_ctx(ctx, CliCtx(
        cwd=device_instance.ssh_auth.dir,
        user_id=user_id
    ))


def run_cli() -> None:
    cli()
