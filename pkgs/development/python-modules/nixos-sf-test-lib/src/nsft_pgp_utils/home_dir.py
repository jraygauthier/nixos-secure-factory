
import os
import subprocess

from pathlib import Path

from nsft_system_utils.permissions_simple import get_file_mode_simple

from .process import OptGpgProcContextSoftT, ensure_gpg_context, run_gpg


def _create_and_assign_proper_permissions_to_dir(
    target_dir: Path,
    mode: int
) -> None:
    if not target_dir.exists():
        target_dir.mkdir(parents=True, exist_ok=True)

    if mode != get_file_mode_simple(target_dir):
        target_dir.chmod(mode)


def create_and_assign_proper_permissions_to_user_home_dir(
        home_dir: Path
) -> None:
    _create_and_assign_proper_permissions_to_dir(home_dir, 0o700)


def create_and_assign_proper_permissions_to_gpg_home_dir(
        proc_ctx: OptGpgProcContextSoftT = None
) -> None:
    proc_ctx = ensure_gpg_context(proc_ctx)
    gpg_home_dir_already_exists = os.path.exists(proc_ctx.home_dir)

    _create_and_assign_proper_permissions_to_dir(proc_ctx.home_dir, 0o700)
    pkeys_subdir = proc_ctx.home_dir.joinpath("private-keys-v1.d")
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
        proc_ctx=proc_ctx)
