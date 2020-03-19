import subprocess
from pathlib import Path

from .process import run_gpg, OptGpgProcContextSoftT
from .query import list_gpg_keys


def import_gpg_key_file(
    in_filename: Path,
    proc_ctx: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import", f"{in_filename}"
    ]

    run_gpg(
        args, text=True, check=True, proc_ctx=proc_ctx)


def import_gpg_key_text(
    armored_text: str,
    proc_ctx: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import"
    ]

    run_gpg(
        args, text=True, input=armored_text, check=True, proc_ctx=proc_ctx)


def import_gpg_otrust_file(
    in_filename: Path,
    proc_ctx: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import-ownertrust", f"{in_filename}"
    ]

    run_gpg(
        args, text=True, check=True, proc_ctx=proc_ctx)

    # WORKAROUND: Strangely, we noticed that the first listing of key occuring
    # after importing ownertrust fails with an error code of 2 and no sensible
    # error message. Subsequent listing are ok. We thus trigger the error
    # here so that subsequent calls remain unafected.
    try:
        list_gpg_keys(proc_ctx=proc_ctx)
    except subprocess.CalledProcessError as e:
        if 2 != e.returncode:
            raise  # re-raise
