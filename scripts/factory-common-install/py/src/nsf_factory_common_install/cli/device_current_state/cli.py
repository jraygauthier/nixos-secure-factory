from typing import Iterable, Optional

import click

from nsf_factory_common_install.cli.device_state import (
    CliCtxDbDeviceInstance,
    CliCtxDbInterface,
)
from nsf_factory_common_install.cli.device_state import cli as cli_base
from nsf_factory_common_install.cli.device_state import (
    init_cli_ctx,
    mk_cli_context_settings,
)
from nsf_factory_common_install.cli.options import (
    ensure_device_cfg_repo_device_by_id_or_current,
)
from nsf_factory_common_install.repo_project import mk_project_repo


class CliCtxDb(CliCtxDbInterface):
    def __init__(self, ctx: click.Context) -> None:
        self.project = mk_project_repo()

    def get_current_device(self) -> Optional[CliCtxDbDeviceInstance]:
        return self.project.current_device.get_instance_from_default_repo_opt()

    def list_device_instances(self) -> Iterable[CliCtxDbDeviceInstance]:
        return self.project.device_cfg.iter_instances()

    def get_device_instance(
            self, device_id: str) -> CliCtxDbDeviceInstance:
        return self.project.device_cfg.get_instance_for(device_id)

    def list_device_states(self) -> Iterable[str]:
        # TODO: request the nsf-ssh-auth lib for this information instead.
        try:
            yield from (
                d.stem for d in self.project.device_cfg.ssh_auth.dir.joinpath(
                    "authorized-on").iterdir())
        except FileNotFoundError:
            pass


@click.group(
    cls=click.CommandCollection,
    sources=[cli_base],
    context_settings=mk_cli_context_settings(
        mk_db=CliCtxDb
    )
)
@click.pass_context
def cli(ctx: click.Context) -> None:
    """Operations on a *current* device state file.

    This is the file usually named `.current-device.yaml` at the
    root of the *workspace dir*.
    """
    device_id = None

    project = mk_project_repo()

    device = ensure_device_cfg_repo_device_by_id_or_current(device_id, project)

    ws_state_file = project.workspace.current_device.state_file

    init_cli_ctx(
        ctx,
        device=device,
        rw_target_file=ws_state_file,
        explicit_device_id=device_id,
        checkout_device_repo=project.device_cfg,
        checkout_target_file=ws_state_file
    )


def run_cli() -> None:
    cli()
