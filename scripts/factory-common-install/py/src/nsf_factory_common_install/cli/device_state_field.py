import click
from ._device_state_ctx import CliCtx, pass_cli_ctx


@click.group()
def field() -> None:
    pass


@field.command()
@pass_cli_ctx
def set(ctx: CliCtx) -> None:
    pass


@field.command()
@pass_cli_ctx
def get(ctx: CliCtx) -> None:
    pass

