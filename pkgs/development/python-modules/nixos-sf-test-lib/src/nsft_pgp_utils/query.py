from dataclasses import dataclass
from typing import Iterator, List, Optional

from .process import OptGpgContextSoftT, gpg_stdout_it


@dataclass
class GpgKeyWEmail:
    key: str
    email: str


def _list_gpg_keys_lines_it(
        email: Optional[str] = None,
        secret: bool = False,
        passphrase: Optional[str] = None,
        gpg_ctx: OptGpgContextSoftT = None
) -> Iterator[str]:
    args = [
        "--list-options", "show-only-fpr-mbox",
    ]

    if secret:
        args.append("--list-secret-keys")
    else:
        args.append("--list-keys")

    if passphrase is not None:
        args.extend([
            "--passphrase", passphrase
        ])

    yield from gpg_stdout_it(args, gpg_ctx=gpg_ctx)


def list_gpg_keys_it(
        email: Optional[str] = None,
        secret: bool = False,
        passphrase: Optional[str] = None,
        gpg_ctx: OptGpgContextSoftT = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_it(
            email, secret, passphrase, gpg_ctx):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys(
        email: Optional[str] = None,
        secret: bool = False,
        passphrase: Optional[str] = None,
        gpg_ctx: OptGpgContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(email, secret, passphrase, gpg_ctx))
