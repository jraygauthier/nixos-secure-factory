from typing import Iterator, List

from .process import OptGpgProcContextSoftT, gpg_stdout_it
from .auth import OptGpgAuthContext
from .types import GpgKeyWEmail, GpgKeyWTrust
from ._export_impl import _export_gpg_otrust_to_str
from ._file_formats_impl import _parse_otrust_content_it


def _list_gpg_keys_lines_it(
        secret: bool = False,
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None
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
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_it(
            secret, auth_ctx, proc_ctx):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys(
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(False, auth_ctx, proc_ctx))


def list_gpg_secret_keys(
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(True, auth_ctx, proc_ctx))


def list_gpg_ownertrust(
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None) -> List[GpgKeyWTrust]:
    content_str = _export_gpg_otrust_to_str(auth_ctx=auth_ctx, proc_ctx=proc_ctx)
    return list(_parse_otrust_content_it(content_str))
