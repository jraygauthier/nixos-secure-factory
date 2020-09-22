#!/usr/bin/env python
import sys
import textwrap
from typing import Any, Dict

import click
import yaml

from .prompt import prompt_for_user_approval
from .store_device_current import (
    dump_to_current_device_info_ws_yaml_store,
    get_current_device_info_ws_yaml_store_filename,
)
from .store_devices import (
    list_ac_available_device_ids,
    load_device_info_from_store_cfg_plain,
    match_unique_device_id,
    MatchNotUniqueError
)


def format_cfg_as_yaml_str(in_cfg: Dict[str, Any]) -> str:
    # We want to preserve key order, thus the `sort_keys=False`.
    return yaml.safe_dump(in_cfg, sort_keys=False)


@click.command()
@click.argument(
    "device-id",
    type=click.STRING,
    autocompletion=list_ac_available_device_ids
)
def checkout_cli(device_id) -> None:
    """Checkout a particular device state."""
    print((
        "Checking out device state\n"
        "=========================\n"
    ).format())
    try:
        matched_device_id = match_unique_device_id(device_id)
    except MatchNotUniqueError as e:
        print(e)
        sys.exit(1)

    device_cfg = load_device_info_from_store_cfg_plain(matched_device_id)

    device_cfg_yaml_str = format_cfg_as_yaml_str(device_cfg)
    print(textwrap.dedent('''\
        Device info
        -----------

        {}\
    ''').format(device_cfg_yaml_str))

    if not prompt_for_user_approval():
        sys.exit(1)

    store_yaml = get_current_device_info_ws_yaml_store_filename()
    print("Writing device configuration to '{}'.".format(store_yaml))
    dump_to_current_device_info_ws_yaml_store(device_cfg, store_yaml)
    print("Current device is now set to '{}'.".format(matched_device_id))


def run_cli_checkout() -> None:
    sys.exit(checkout_cli())


def run_cli_field() -> None:
    # TODO: Implement.
    raise NotImplementedError
