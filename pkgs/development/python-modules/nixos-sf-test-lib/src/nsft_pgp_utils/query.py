from dataclasses import dataclass
from typing import Iterator, List

from .process import OptGpgProcContextSoftT, gpg_stdout_it
from .auth import OptGpgAuthContext


@dataclass
class GpgKeyWEmail:
    key: str
    email: str


def _list_gpg_keys_lines_it(
        secret: bool = False,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None
) -> Iterator[str]:
    args = [
        "--list-options", "show-only-fpr-mbox",
    ]

    if secret:
        args.append("--list-secret-keys")
    else:
        args.append("--list-keys")

    yield from gpg_stdout_it(
        args, proc_ctx=proc_ctx, auth_ctx=auth_ctx)


def list_gpg_keys_it(
        secret: bool = False,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_it(
            secret, proc_ctx, auth_ctx):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys(
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(False, proc_ctx, auth_ctx))


def list_gpg_secret_keys(
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(True, proc_ctx, auth_ctx))


def _list_gpg_keys_lines_from_file_it(
        in_filename: str,
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
        in_filename: str,
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
        in_filename: str,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_from_file_it(in_filename, proc_ctx))


def list_gpg_keys_from_text(
        in_amored_text: str,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_from_text_it(in_amored_text, proc_ctx))
