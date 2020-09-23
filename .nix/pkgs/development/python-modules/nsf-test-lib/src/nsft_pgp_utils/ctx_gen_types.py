from dataclasses import dataclass, field
from pathlib import Path
from typing import List

from .ctx_proc_types import mk_gpg_proc_ctx_for_user_home_dir
from .ctx_auth_types import mk_gpg_no_pass_auth_ctx
from .ctx_types import GpgContext


@dataclass
class GpgKeyGenInfo:
    user_name: str
    email: str


@dataclass
class GpgContextGenInfo:
    public_keys: List[GpgKeyGenInfo] = field(default_factory=(lambda: []))
    secret_keys: List[GpgKeyGenInfo] = field(default_factory=(lambda: []))


def get_empty_gpg_ctx_gen_info() -> GpgContextGenInfo:
    return GpgContextGenInfo()


@dataclass
class GpgContextWGenInfo(GpgContext):
    gen_info: GpgContextGenInfo = field(default_factory=get_empty_gpg_ctx_gen_info)


def mk_gpg_ctx_w_gen_info_for_user_home_dir(
        home_dir: Path, gen_info: GpgContextGenInfo) -> GpgContextWGenInfo:
    return GpgContextWGenInfo(
        proc=mk_gpg_proc_ctx_for_user_home_dir(home_dir),
        auth=mk_gpg_no_pass_auth_ctx(),
        gen_info=gen_info
    )
