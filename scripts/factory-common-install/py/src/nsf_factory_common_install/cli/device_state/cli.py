from typing import Iterable, Optional

import click

from nsf_factory_common_install.repo_project import mk_project_repo

from ..options import (
    cli_default_device_option,
    ensure_device_cfg_repo_device_by_id_or_current,
)
from ._ctx import (
    CliCtx,
    CliCtxDbDeviceInstance,
    CliCtxDbInterface,
    init_cli_ctx,
    mk_cli_context_settings,
    pass_cli_ctx,
)
from .checkout import checkout
from .create import create
from .field import field
from .file import file_


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
    context_settings=mk_cli_context_settings(
        mk_db=CliCtxDb
    )
)
@cli_default_device_option()
@click.pass_context
def cli(ctx: click.Context, device_id: Optional[str]) -> None:
    """Operations on a the device state file part of the the
        device configuration repository.

    Defaults to operating on the *current device* / currently
    checked-out device when device not explicitly specified.

    Note however the print and field r/w target only the device
    state directory in the device cfg (e.g.:
    `[my-device-cfg-repo]/device/[my-device-id]/device-info.json`).

    The checkout does bring the in-repo state to
    `.current-device.yaml` for further customizations.

    See also `device-current-state` targetting only the workspace
    version of the device state (aka `.current-device.yaml`).
    """
    project = mk_project_repo()

    device = ensure_device_cfg_repo_device_by_id_or_current(device_id, project)

    cfg_state_file = device.state_file
    ws_state_file = project.workspace.current_device.state_file

    init_cli_ctx(
        ctx,
        device=device,
        rw_target_file=cfg_state_file,
        explicit_device_id=device_id,
        checkout_device_repo=project.device_cfg,
        checkout_target_file=ws_state_file
    )


@cli.command(name="info")
@pass_cli_ctx
def _info(ctx: CliCtx) -> None:
    click.echo(
        f"target-device-id: {str(ctx.device.id)}")
    click.echo(
        "target-filename: "
        f"'{str(ctx.rw_target_file.filename)}'")
    if ctx.checkout_device_repo is not None:
        click.echo(
            "checkout-device-repo: "
            f"'{str(ctx.checkout_device_repo.dir)}'")

    if ctx.checkout_target_file is not None:
        click.echo(
            "checkout-target-filename: "
            f"'{str(ctx.checkout_target_file.filename)}'")


cli.add_command(file_)
cli.add_command(field)
cli.add_command(checkout)
cli.add_command(create)


def run_cli() -> None:
    cli()
