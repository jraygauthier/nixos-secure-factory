from typing import Iterator, List
from pathlib import Path

from .process import OptGpgProcContextSoftT, gpg_stdout_it
from .types import GpgKeyWEmail, GpgKeyWTrust

from ._file_formats_impl import _parse_otrust_content_it


def _list_gpg_keys_lines_from_file_it(
        in_filename: Path,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Iterator[str]:
    args = [
        "--import-options", "show-only",
        "--list-options", "show-only-fpr-mbox",
        "--import", f"{in_filename}"
    ]

    yield from gpg_stdout_it(
        args, proc_ctx=proc_ctx)


def _list_gpg_keys_lines_from_text_it(
        in_amored_text: str,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Iterator[str]:
    args = [
        "--import-options", "show-only",
        "--list-options", "show-only-fpr-mbox",
        "--import"
    ]

    yield from gpg_stdout_it(
        args, input=in_amored_text, proc_ctx=proc_ctx)


def list_gpg_keys_from_file_it(
        in_filename: Path,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_from_file_it(
            in_filename, proc_ctx):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys_from_text_it(
        in_amored_text: str,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_from_text_it(
            in_amored_text, proc_ctx):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys_from_file(
        in_filename: Path,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_from_file_it(in_filename, proc_ctx))


def list_gpg_keys_from_text(
        in_amored_text: str,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_from_text_it(in_amored_text, proc_ctx))


def list_gpg_ownertrust_from_text(in_text: str) -> List[GpgKeyWTrust]:
    return list(_parse_otrust_content_it(in_text))


def list_gpg_ownertrust_from_file(in_filename: Path) -> List[GpgKeyWTrust]:
    with open(in_filename) as f:
        content_str = f.read()
    return list_gpg_ownertrust_from_text(content_str)
