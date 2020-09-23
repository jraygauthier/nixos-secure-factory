from pathlib import Path
from typing import Iterable

from .trust_types import convert_gpg_otrust_to_exp_otrust
from .process import run_gpg, OptGpgProcContextSoftT
from .query import list_gpg_keys
from .errors import GpgProcessError
from .key_types import GpgKeyWUIOwnerTrust


def import_gpg_key_file(
    in_filename: Path,
    proc: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import", f"{in_filename}"
    ]

    run_gpg(
        args, text=True, check=True, proc=proc)


def import_gpg_key_text(
    armored_text: str,
    proc: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import"
    ]

    run_gpg(
        args, text=True, input=armored_text, check=True, proc=proc)


def _import_otrust_list_key_workaround(proc: OptGpgProcContextSoftT) -> None:
    # WORKAROUND: Strangely, we noticed that the first listing of key occuring
    # after importing ownertrust fails with an error code of 2 and no sensible
    # error message. Subsequent listing are ok. We thus trigger the error
    # here so that subsequent calls remain unafected.
    try:
        list_gpg_keys(proc=proc)
    except GpgProcessError as e:
        if 2 != e.returncode:
            raise  # re-raise


def import_gpg_otrust_file(
    in_filename: Path,
    proc: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import-ownertrust", f"{in_filename}"
    ]

    run_gpg(
        args, text=True, check=True, proc=proc)

    _import_otrust_list_key_workaround(proc)


def import_gpg_otrust_text(
    in_text: str,
    proc: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--import-ownertrust"
    ]

    run_gpg(
        args, text=True, input=f"{in_text}", check=True, proc=proc)

    _import_otrust_list_key_workaround(proc)


def _format_gpg_otrust(otrust: Iterable[GpgKeyWUIOwnerTrust]) -> str:
    otrust_str = "\n".join(
        map(
            lambda x:
                f"{x.fpr}:{convert_gpg_otrust_to_exp_otrust(x.trust)}:",
            otrust))

    return f"{otrust_str}\n"


def import_gpg_ui_otrust(
    otrust: Iterable[GpgKeyWUIOwnerTrust],
    proc: OptGpgProcContextSoftT = None
) -> None:
    otrust_str = _format_gpg_otrust(otrust)
    import_gpg_otrust_text(
        otrust_str, proc)
