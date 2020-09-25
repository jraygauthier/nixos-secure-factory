from typing import Optional

import click

from nsf_factory_common_install.cli.click import is_click_requesting_shell_completion
from nsf_factory_common_install.cli.options import (
    cli_default_user_option,
    ensure_user_id_or_user_factory_user_id,
)
from nsf_factory_common_install.repo_project import mk_project_repo
from nsf_ssh_auth_dir.cli import CliCtx
from nsf_ssh_auth_dir.cli import cli as cli_base
from nsf_ssh_auth_dir.cli import init_cli_ctx


@click.group(cls=click.CommandCollection, sources=[cli_base])
@cli_default_user_option()
@click.pass_context
def cli(ctx: click.Context, user_id: Optional[str]) -> None:
    """Ssh authorization tool for nixos-secure-factory projects.

    Operates on the *cfg*'s **common** *auth-dir*.
    That is, the set of authorizations shared by all devices.

    You can get more information about the target authorization
    directory using the `info` sub-command.

    Note that it remains **you responsability** to add / commit /
    push your changes to *version control*. We however provide
    some `git` helpers under `[cmd] git`.
    """
    if is_click_requesting_shell_completion():
        return

    project = mk_project_repo()

    user_id = ensure_user_id_or_user_factory_user_id(user_id, project)

    init_cli_ctx(ctx, CliCtx(
        cwd=project.device_cfg.ssh_auth.dir,
        user_id=user_id
    ))


def run_cli() -> None:
    cli()
