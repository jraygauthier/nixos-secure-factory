
import os
from pathlib import Path

from .sh_process import collect_process_stdout


def get_nsf_workspace_dir_path() -> Path:
    ws_dir = collect_process_stdout(
        "pkg-nsf-factory-common-install-get-workspace-dir")
    assert ws_dir.exists()
    return ws_dir


def get_device_cfg_repo_root_dir_path() -> Path:
    env_var_name = "PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR"
    out = os.environ.get(env_var_name, None)
    if out is None:
        raise Exception((
            "ERROR: Env var '{}' "
            "should be set to point to the device "
            "configuration repository!").format(
                env_var_name)
        )

    return Path(out)
