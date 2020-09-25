
from pathlib import Path

import click
import yaml

from nsf_factory_common_install.file_device_state import (
    DeviceStateFileAccessError, DeviceStatePlainT)

from ..click import CliError
from ._ctx import CliCtx, pass_cli_ctx
from ._field_ac import (list_ac_editable_field_names, list_ac_field_values,
                        list_ac_readable_field_names,
                        list_ac_removable_field_names)
from ._fields_schema import get_field_schema


@click.group()
def field() -> None:
    pass


@field.command(name="ls")
@pass_cli_ctx
def _ls(ctx: CliCtx) -> None:
    try:
        state_d = ctx.rw_target_file.load_plain()
    except DeviceStateFileAccessError as e:
        raise CliError(str(e)) from e

    for k in state_d.keys():
        click.echo(k)


def _confirm_create_missing_state_file(filename: Path) -> bool:
    return click.confirm((
        f"State file '{filename}' does not exit.\n"
        "Do you want to create it?"
    ), err=True, abort=True)


@field.command(name="set")
@click.option(
    "-y", "--yes", "prompt_auto_yes",
    is_flag=True,
    default=False,
    help="Systematically answer yes when prompted."
)
@click.option(
    "--yes-field", "prompt_auto_yes_create_field",
    is_flag=True,
    default=False,
    help=(
        "Systematically answer yes when "
        "prompted to create missing fields.")
)
@click.argument(  # type: ignore
    "field-name",
    autocompletion=list_ac_editable_field_names
)
@click.argument(  # type: ignore
    "field-value",
    autocompletion=list_ac_field_values
)
@pass_cli_ctx
def _set(
        ctx: CliCtx,
        field_name: str, field_value: str,
        prompt_auto_yes: bool,
        prompt_auto_yes_create_field: bool
) -> None:
    """Set the value of a the field of the target device state file.

    By default, you will be prompted for
    """
    prompt_auto_yes_create_file = prompt_auto_yes
    prompt_auto_yes_create_field = (
        prompt_auto_yes or prompt_auto_yes_create_field)

    state_d: DeviceStatePlainT = {}

    target_file = ctx.rw_target_file

    try:
        state_d = target_file.load_plain()
    except DeviceStateFileAccessError as e:
        if (not prompt_auto_yes_create_file
                and not _confirm_create_missing_state_file(
                    target_file.filename)):
            raise CliError(str(e)) from e

        target_file.filename.parent.mkdir(exist_ok=True, parents=True)
        target_file.filename.touch()

    sanitized_value = get_field_schema(field_name).sanitize(ctx.db, field_value)

    try:
        state_d[field_name] = sanitized_value
    except KeyError:
        raise CliError(f"Cannot find field '{field_name}'")

    try:
        ctx.rw_target_file.dump_plain(state_d)
    except DeviceStateFileAccessError as e:
        raise CliError(str(e)) from e


@field.command(name="get")
@click.argument(  # type: ignore
    "field-name",
    autocompletion=list_ac_readable_field_names
)
@pass_cli_ctx
def _get(ctx: CliCtx, field_name: str) -> None:
    try:
        out_str = ctx.rw_target_file.load_plain()[field_name]
    except KeyError:
        out_str = "null"
        click.echo("null")
        raise CliError(f"Cannot find field '{field_name}'")
    except DeviceStateFileAccessError as e:
        raise CliError(str(e)) from e

    if out_str is None:
        out_str = "null"

    if not isinstance(out_str, str):
        raise CliError(
            "Not a field. Please be more specific:\n"
            f"{yaml.safe_dump(out_str, sort_keys=False)}")

    click.echo(out_str)


# TODO: Consider allowing rm multiple fields at a time.
@field.command(name="rm")
@click.argument(  # type: ignore
    "field-name",
    autocompletion=list_ac_removable_field_names
)
@pass_cli_ctx
def _rm(ctx: CliCtx, field_name: str) -> None:
    try:
        state_d = ctx.rw_target_file.load_plain()
    except DeviceStateFileAccessError as e:
        raise CliError(str(e)) from e

    # TODO: Consider preventing the removal of some mandatory
    # fields.

    try:
        del state_d[field_name]
    except KeyError:
        raise CliError(f"Cannot find field '{field_name}'")

    try:
        ctx.rw_target_file.dump_plain(state_d)
    except DeviceStateFileAccessError as e:
        raise CliError(str(e)) from e
