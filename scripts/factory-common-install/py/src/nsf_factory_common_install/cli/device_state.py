import click
from pathlib import Path

from .device_state_field import field
from .device_state_checkout import checkout
from ._device_state_ctx import CliCtx, init_cli_ctx, pass_cli_ctx


@click.group()
@click.pass_context
def cli(ctx: click.Context) -> None:
    init_cli_ctx(ctx, CliCtx(
        state_file=Path.cwd().joinpath("device.json"),
        override_state_file=Path.cwd().joinpath(".current-device.yaml")
    ))


@cli.command()
def print() -> None:
    # TODO: Re-implement the `bin/device-state-print` bash command
    # in python here. Do not forget to update doc.
    pass


cli.add_command(field)
cli.add_command(checkout)


def run_cli() -> None:
    cli()
