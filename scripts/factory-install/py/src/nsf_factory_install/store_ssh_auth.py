from pathlib import Path
from typing import Optional

from nsf_factory_common_install.store_device_current import \
    ensure_device_id_or_current
from nsf_factory_common_install.store_devices import \
    get_device_specific_cfg_dir_path

from nsf_factory_common_install.workspace_paths import get_device_cfg_repo_root_dir_path


def get_common_ssh_auth_dir_path() -> Path:
    return get_device_cfg_repo_root_dir_path().joinpath("device-ssh")


def get_device_specific_ssh_auth_dir_path(
        device_id: Optional[str] = None) -> Path:
    device_id = ensure_device_id_or_current(device_id)
    return get_device_specific_cfg_dir_path(device_id).joinpath("ssh")
