import os
import json
from pathlib import Path
from typing import List, Optional, Dict, Any
from itertools import islice, chain

from .repo_device_cfg import get_device_cfg_paths


def list_available_device_ids() -> List[str]:
    root_dir = get_device_cfg_paths().instance_set_dir
    out = list(chain.from_iterable(x[1] for x in islice(os.walk(root_dir), 0, 1)))
    return out


def match_device_id(
        search_str: str, available_devices: Optional[List[str]] = None
) -> List[str]:
    if available_devices is None:
        available_devices = list_available_device_ids()

    out = [x for x in available_devices if x.startswith(search_str)]
    if out:
        return out

    return [x for x in available_devices if search_str in x]


def list_ac_available_device_ids(ctx, args, incomplete: str) -> List[str]:
    return match_device_id(incomplete)


def get_device_specific_cfg_dir_path(device_id: str) -> Path:
    return get_device_cfg_paths().instance_set_dir.joinpath(device_id)


def ensure_specific_device_cfg_dir_path(device_id: str) -> Path:
    dir_path = get_device_specific_cfg_dir_path(device_id)
    dir_path.stat()
    return dir_path


def get_device_info_json_cfg_path(device_id: str) -> Path:
    return get_device_cfg_paths().instance_set_dir.joinpath(device_id, "device.json")


def load_device_info_from_store_cfg_plain(device_id: str) -> Dict[str, Any]:
    json_cfg_path = get_device_info_json_cfg_path(device_id)
    with open(json_cfg_path) as f:
        # We want to preserve key order. Json already does that.
        out = json.load(f)

    assert out is not None
    return out


class MatchNotUniqueError(Exception):
    pass


def format_available_devices_str(devices: List[str]) -> str:
    devices_str = "\n".join(devices)
    available_devices_msg_str = (
        "Available devices\n"
        "------------------\n\n"
        "{}\n"
    ).format(devices_str)
    return available_devices_msg_str


def format_matching_devices_str(devices: List[str]) -> str:
    devices_str = "\n".join(devices)
    available_devices_msg_str = (
        "Matching devices\n"
        "----------------\n\n"
        "{}\n"
    ).format(devices_str)
    return available_devices_msg_str


def match_unique_device_id(search_str: str) -> str:
    available_devices = list_available_device_ids()
    matching_devices = match_device_id(search_str, available_devices)
    if not matching_devices:
        available_devices_msg_str = format_available_devices_str(
            available_devices)
        raise MatchNotUniqueError((
            "ERROR: No device dirname match specified "
            "search string: '{}'.\n\n{}"
        ).format(
            search_str,
            available_devices_msg_str
        ))

    matching_count = len(matching_devices)
    if matching_count > 1:
        matching_devices_msg_str = format_matching_devices_str(matching_devices)
        raise MatchNotUniqueError((
            "ERROR: Too many dirname match for the specified "
            "search string: '{}'\n\n{}"
        ).format(
            search_str,
            matching_devices_msg_str
        ))

    assert matching_count == 1
    return matching_devices[0]
