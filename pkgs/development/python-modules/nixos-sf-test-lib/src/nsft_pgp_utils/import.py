from pathlib import Path

from .process import run_gpg, OptGpgProcContextSoftT


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


def import_gpg_public_key_text(
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
