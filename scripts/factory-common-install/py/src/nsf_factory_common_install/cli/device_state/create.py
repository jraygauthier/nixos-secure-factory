import click

from nsf_factory_common_install.cli.click import CliError
from nsf_factory_common_install.file_device_state import (
    DeviceStateFileError,
    DeviceStatePlainT,
    format_plain_device_state_as_yaml_str,
)

from ._ctx import CliCtx, pass_cli_ctx


@click.command()
@click.option(
    "--overwrite",
    is_flag=True,
    default=False,
    help="Overwrite existing."
)
@click.option(
    "-q", "--quiet", "--silent", "quiet",
    is_flag=True,
    default=False,
    help="Suppress non essential output."
)
@pass_cli_ctx
def create(ctx: CliCtx, overwrite: bool, quiet: bool) -> None:
    target_file = ctx.rw_target_file

    if not overwrite and target_file.filename.exists():
        try:
            device_state_d = target_file.load_plain()
        except DeviceStateFileError:
            device_state_d = {}

        file_content_str = format_plain_device_state_as_yaml_str(device_state_d)

        raise CliError(
            "Nothing to do. "
            f"File '{target_file.filename}' already exits with content: "
            f"''\n{file_content_str}\n''\n"
        )

    # TODO: Make it possible for library user to provide interractive
    # script that prompt user for missing required fields.
    # In the meantime, create a empty file.

    target_file.filename.parent.mkdir(parents=True, exist_ok=True)
    empty_state_d: DeviceStatePlainT = {}
    target_file.dump_plain(empty_state_d)
    click.echo(f"Created empty file at '{target_file.filename}'.")
    click.echo(
        "Please use the `field set` command to at least "
        "enter mandatory fields if any.")
