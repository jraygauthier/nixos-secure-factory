from dataclasses import dataclass
from typing import Optional


@dataclass
class GpgAuthContext:
    passphrase: Optional[str] = None


OptGpgAuthContext = Optional[GpgAuthContext]


def get_default_gpg_auth_ctx() -> GpgAuthContext:
    return GpgAuthContext(passphrase=None)


def mk_gpg_no_pass_auth_ctx() -> GpgAuthContext:
    return GpgAuthContext(passphrase="")


def ensure_gpg_auth_ctx(
        auth: OptGpgAuthContext = None
) -> GpgAuthContext:
    if auth is None:
        return get_default_gpg_auth_ctx()

    return auth
