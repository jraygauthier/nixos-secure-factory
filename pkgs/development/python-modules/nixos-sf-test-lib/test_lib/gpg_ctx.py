from pathlib import Path
from dataclasses import dataclass
from typing import List
from nsft_pgp_utils.process import GpgProcContextExp, ensure_gpg_context
from nsft_pgp_utils.auth import GpgAuthContext


@dataclass
class GpgKeyInfo:
    user_name: str
    email: str


@dataclass
class GpgContextInfo:
    secret_keys: List[GpgKeyInfo]


@dataclass
class GpgContext:
    proc: GpgProcContextExp
    auth: GpgAuthContext


@dataclass
class GpgContextWInfo(GpgContext):
    info: GpgContextInfo


def mk_gpg_proc_ctx_for(user_home_dir: Path) -> GpgProcContextExp:
    gpg_home_dir = user_home_dir.joinpath(".gnupg")
    return ensure_gpg_context((None, gpg_home_dir))


def mk_gpg_ctx_w_info(home_dir: Path, info: GpgContextInfo) -> GpgContextWInfo:
    return GpgContextWInfo(
        proc=mk_gpg_proc_ctx_for(home_dir),
        auth=GpgAuthContext(passphrase=""),
        info=info
    )
