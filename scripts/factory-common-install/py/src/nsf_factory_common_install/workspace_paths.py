
import os
from pathlib import Path

from .sh_process import collect_process_stdout


def get_nsf_workspace_dir_path() -> Path:
    ws_dir = collect_process_stdout(
        "pkg-nixos-sf-factory-common-install-get-workspace-dir")
    assert ws_dir.exists()
    return ws_dir


def get_device_cfg_repo_root_dir_path() -> Path:
    env_var_name = "PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR"
    out = os.environ.get(env_var_name, None)
    if out is None:
        raise Exception((
            "ERROR: Env var '{}' "
            "should be set to point to the device "
            "configuration core repository!").format(
                env_var_name)
        )

    return Path(out)


def get_device_cfg_device_dir_path() -> Path:
    out_dir = get_device_cfg_repo_root_dir_path().joinpath("device")
    if not out_dir.exists():
        raise Exception("ERROR: Directory '{}' does not exists!".format(out_dir))
    return out_dir
