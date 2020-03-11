
import os
import subprocess
from nsft_system_utils.permissions_simple import get_file_mode_simple

from .process import OptGpgContextSoftT, ensure_gpg_context, run_gpg


def _create_and_assign_proper_permissions_to_dir(
    target_dir: str,
    mode: int
) -> None:
    if not os.path.exists(target_dir):
        os.makedirs(target_dir, exist_ok=True)

    if mode != get_file_mode_simple(target_dir):
        os.chmod(target_dir, mode)


def create_and_assign_proper_permissions_to_gpg_home_dir(
        gpg_ctx: OptGpgContextSoftT = None
) -> None:
    gpg_ctx = ensure_gpg_context(gpg_ctx)
    gpg_home_dir_already_exists = os.path.exists(gpg_ctx.home_dir)

    _create_and_assign_proper_permissions_to_dir(gpg_ctx.home_dir, 0o700)
    pkeys_subdir = os.path.join(gpg_ctx.home_dir, "private-keys-v1.d")
    _create_and_assign_proper_permissions_to_dir(pkeys_subdir, 0o700)

    if gpg_home_dir_already_exists:
        return

    # Force automated creation of missing files.
    args = [
        "--list-keys",
    ]
    run_gpg(
        args, check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        gpg_ctx=gpg_ctx)
