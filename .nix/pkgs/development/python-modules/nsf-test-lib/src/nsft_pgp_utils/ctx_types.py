from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any

from .ctx_auth_types import (
    GpgAuthContext,
    OptGpgAuthContext,
    ensure_gpg_auth_ctx,
    get_default_gpg_auth_ctx,
)
from .ctx_proc_types import (
    GpgProcContextExp,
    OptGpgProcContextSoftT,
    ensure_gpg_proc_ctx,
    get_default_gpg_proc_ctx,
    mk_gpg_proc_ctx_for_user_home_dir,
)
from .key_types import GpgKeyWExtInfoWOTrust


@dataclass
class GpgContext:
    proc: GpgProcContextExp = field(default_factory=get_default_gpg_proc_ctx)
    auth: GpgAuthContext = field(default_factory=get_default_gpg_auth_ctx)

    def as_proc_dict(self) -> Dict[str, Any]:
        return {
            'proc': self.proc
        }

    def as_proc_auth_dict(self) -> Dict[str, Any]:
        return {
            'proc': self.proc,
            'auth': self.auth
        }


def mk_gpg_ctx_for_user_home_dir(
        home_dir: Path,
        auth: OptGpgAuthContext = None) -> GpgContext:
    return GpgContext(
        proc=mk_gpg_proc_ctx_for_user_home_dir(home_dir),
        auth=ensure_gpg_auth_ctx(auth)
    )


@dataclass
class GpgContextKeysWExtInfo:
    public: List[GpgKeyWExtInfoWOTrust] = field(default_factory=(lambda: []))
    secret: List[GpgKeyWExtInfoWOTrust] = field(default_factory=(lambda: []))

    @property
    def all(self):
        return self.public + self.secret


def mk_default_ctx_keys_w_ext_info() -> GpgContextKeysWExtInfo:
    return GpgContextKeysWExtInfo()


@dataclass
class GpgContextWExtInfo(GpgContext):
    keys: GpgContextKeysWExtInfo = field(
        default_factory=mk_default_ctx_keys_w_ext_info)


def ensure_gpg_ctx(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None):
    return GpgContext(
        auth=ensure_gpg_auth_ctx(auth),
        proc=ensure_gpg_proc_ctx(proc))


def mk_empty_gpg_ctx_w_ext_info(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> GpgContextWExtInfo:
    ctx = ensure_gpg_ctx(auth, proc)
    return GpgContextWExtInfo(**ctx.__dict__)
