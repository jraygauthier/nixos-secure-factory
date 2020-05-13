import yaml
from pathlib import Path
from typing import Any, Dict, Optional

from .workspace_paths import (
    get_nsf_workspace_dir_path,
)

from .file_device_info import load_device_id_from_device_info_yaml_file
from .store_devices import get_device_specific_cfg_dir_path


def get_current_device_info_ws_yaml_store_filename() -> Path:
    device_cfg_repo_root_dir = get_nsf_workspace_dir_path()
    return device_cfg_repo_root_dir.joinpath(".current-device.yaml")


def dump_to_current_device_info_ws_yaml_store(
        in_cfg: Dict[str, Any],
        out_yaml_file_path: Optional[Path] = None
) -> None:
    if out_yaml_file_path is None:
        out_yaml_file_path = get_current_device_info_ws_yaml_store_filename()
    with open(out_yaml_file_path, 'w') as of:
        # We want to preserve key order, thus the `sort_keys=False`.
        yaml.safe_dump(in_cfg, of, sort_keys=False)


def get_current_device_id() -> str:
    return load_device_id_from_device_info_yaml_file(
        get_current_device_info_ws_yaml_store_filename())


def ensure_device_id_or_current(
        device_id: Optional[str] = None) -> str:
    if device_id is None:
        device_id = get_current_device_id()
    return device_id


def get_current_device_cfg_dir_path() -> Path:
    device_id = get_current_device_id()
    return get_device_specific_cfg_dir_path(device_id)
