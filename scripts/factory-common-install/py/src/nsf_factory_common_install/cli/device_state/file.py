import click

from nsf_factory_common_install.click.error import CliError
from nsf_factory_common_install.file_device_state import (
    DeviceStateFileError,
    format_plain_device_state_as_yaml_str,
)

from ._ctx import CliCtx, pass_cli_ctx


@click.group(name="file")
def file_():
    """Operations on the device state file."""
    pass


@file_.command(name="print")
@pass_cli_ctx
def print_(ctx: CliCtx) -> None:
    input_file = ctx.rw_target_file

    try:
        device_state = input_file.load_plain()
    except DeviceStateFileError as e:
        raise CliError(f"Cannot print the state: {str(e)}") from e

    out_str = format_plain_device_state_as_yaml_str(device_state)
    print(out_str)


@file_.command(name="rm")
@click.option(
    "-q", "--quiet", "--silent", "quiet",
    is_flag=True,
    default=False,
    help="Suppress non essential output."
)
@click.option(
    "-y", "--yes", "prompt_auto_yes",
    is_flag=True,
    default=False,
    help="Systematically answer yes when prompted."
)
@pass_cli_ctx
def rm(ctx: CliCtx, prompt_auto_yes: bool, quiet: bool) -> None:
    input_file = ctx.rw_target_file

    if not input_file.filename.exists():
        if quiet:
            raise click.exceptions.Exit(code=1)

        raise CliError(
            "Nothing to remove. State file at "
            f"'{input_file.filename}' does not exists."
        )

    try:
        device_state_d = input_file.load_plain()
    except DeviceStateFileError:
        device_state_d = {}

    file_content_str = format_plain_device_state_as_yaml_str(device_state_d)

    if not prompt_auto_yes:
        confirmed = click.confirm(
            f"File '{input_file.filename}' with content: "
            f"''\n{file_content_str}\n''\nwill be removed. "
            "Do you want to proceed?",
            err=False,
            abort=True)
        assert confirmed

    input_file.filename.unlink()
