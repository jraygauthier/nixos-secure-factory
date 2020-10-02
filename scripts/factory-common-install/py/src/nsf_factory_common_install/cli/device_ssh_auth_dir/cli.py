from typing import Optional

import click

from nsf_factory_common_install.cli.options import (
    cli_default_device_option, cli_default_user_option,
    ensure_device_cfg_repo_device_by_id_or_current,
    ensure_user_id_or_user_factory_user_id)
from nsf_factory_common_install.click.sh_comp import \
    is_click_requesting_shell_completion
from nsf_factory_common_install.repo_project import mk_project_repo
from nsf_ssh_auth_dir.cli.nsf_ssh_auth_dir import CliCtxDbInterface
from nsf_ssh_auth_dir.cli.nsf_ssh_auth_dir import cli as cli_base
from nsf_ssh_auth_dir.cli.nsf_ssh_auth_dir import (init_cli_ctx,
                                                   mk_cli_context_settings)


class CliCtxDb(CliCtxDbInterface):
    def __init__(self, ctx: click.Context) -> None:
        pass


@click.group(
    cls=click.CommandCollection,
    sources=[cli_base],
    context_settings=mk_cli_context_settings(
        mk_db=CliCtxDb
    )
)
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

    init_cli_ctx(
        ctx,
        repo=device_instance.ssh_auth.dir,
        user_id=user_id
    )


def run_cli() -> None:
    cli()
