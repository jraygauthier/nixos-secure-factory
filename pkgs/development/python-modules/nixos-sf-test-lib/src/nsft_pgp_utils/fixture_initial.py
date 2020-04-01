import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple, Iterable

from .ctx_gen_types import GpgKeyGenInfo
from .ctx_types import (
    GpgContext,
    GpgContextWExtInfo,
    mk_empty_gpg_ctx_w_ext_info,
    mk_gpg_ctx_for_user_home_dir,
)
from .home_dir import (
    create_and_assign_proper_permissions_to_gpg_home_dir,
    create_and_assign_proper_permissions_to_user_home_dir,
)
from .query import query_gpg_context_w_ext_info
from .secret_id import create_gpg_secret_identity
from ._fixture_gen_tools import import_pub_key_for_all_sids_in_ctxs


@dataclass
class _GpgInitialCtxs:
    i_ie: GpgContext

    i_m: GpgContext
    i_f: GpgContext
    i_s: GpgContext
    i_t: GpgContext
    i_z: GpgContext
    # i_u: GpgContext


def _mk_gpg_intial_ctxs(
        homes_root_dir: Path) -> _GpgInitialCtxs:

    def mk_home_dir(user_name: str) -> Path:
        return homes_root_dir.joinpath(user_name)

    user_names = [
        "initial-ie",
        "initial-m",
        "initial-f",
        "initial-s",
        "initial-t",
        "initial-z"
        # "initial_u",
    ]

    ctxs = map(
        lambda u: mk_gpg_ctx_for_user_home_dir(mk_home_dir(u)),
        user_names)

    return _GpgInitialCtxs(
        *ctxs
    )


@dataclass
class GpgInitialFixture:
    # En encrypter who knows about all of the below recipients if any.
    i_ie: GpgContextWExtInfo

    #
    # Not part of any external trust network nor do they know each other.
    #
    # This is a initial, setup or beginner situation.
    #
    # Initial contexes.
    i_m: GpgContextWExtInfo  # Minimal directories exist, no secret id.
    i_f: GpgContextWExtInfo  # Family: two different secret ids.
    i_s: GpgContextWExtInfo  # Single: 1 secret id (i.e: no known ids) ultimate trust.
    i_t: GpgContextWExtInfo  # Twins: Twice the same info, different secret id.
    i_z: GpgContextWExtInfo  # Zero directories. Nothing exists.
    # i_u: GpgContextWExtInfo  # Untrusted secret id only (i.e: no other id known).


def _load_fix_ctx(ctx: GpgContext) -> GpgContextWExtInfo:
    if ctx.proc.home_dir.exists():
        return query_gpg_context_w_ext_info(**ctx.as_proc_auth_dict())

    # In this case, we avoid calling any gpg commands those will
    # oftentime create files in the gpg directory which we want
    # to avoid to preserve this *empty dir* state.
    return mk_empty_gpg_ctx_w_ext_info(**ctx.__dict__)


def load_gpg_initial_fixture(
        homes_root_dir: Path) -> GpgInitialFixture:
    ctxs = _mk_gpg_intial_ctxs(homes_root_dir)
    return GpgInitialFixture(
        *[_load_fix_ctx(ctx)
            for ctx in ctxs.__dict__.values()]
    )


ignore_copy_for_gpg_home_dir = shutil.ignore_patterns(
    "S.gpg-agent", "S.gpg-agent.*", "S.scdaemon")


def copy_gpg_initial_fixture(
        homes_root_dir: Path,
        src: GpgInitialFixture) -> GpgInitialFixture:
    homes_root_dir.mkdir(exist_ok=True)
    for k, v in src.__dict__.items():
        src_hd = v.proc.home_dir
        src_hd_parent_name = src_hd.parent.name
        src_hd_name = src_hd.name
        tgt_hdp = homes_root_dir.joinpath(src_hd_parent_name)
        tgt_hdp.mkdir()
        tgt_hd = tgt_hdp.joinpath(src_hd_name)
        if src_hd.exists():
            shutil.copytree(src_hd, tgt_hd, ignore=ignore_copy_for_gpg_home_dir)

    return load_gpg_initial_fixture(homes_root_dir)


def generate_gpg_initial_fixture(
        homes_root_dir: Path) -> GpgInitialFixture:
    ctxs = _mk_gpg_intial_ctxs(homes_root_dir)

    @dataclass
    class _GenInst:
        secret_ids: Iterable[GpgKeyGenInfo]
        w_min_dirs: bool

    def mk_gen_inst(
            sids: Iterable[Tuple[str, str]],
            w_min_dirs: bool) -> _GenInst:

        skgs = (
            GpgKeyGenInfo(
                user_name=f"{first_name} Secrets",
                email=f"{email_local_part}@secrets.com"
            ) for first_name, email_local_part in sids)

        return _GenInst(skgs, w_min_dirs)

    cases: List[Tuple[List[Tuple[str, str]], bool]] = [
        ([("InitialEncrypterE", "initial-encrypter-e")], False),
        ([], True),
        ([("InitialManF", "initial-man-f"), ("InitialWifeF", "initial-wife-f")], False),
        ([("InitialSingleS", "initial-single-s")], False),
        ([("InitialTwinT", "initial-twin-t")] * 2, False),
        ([], False),
    ]

    ginsts = (mk_gen_inst(*x) for x in cases)

    def gen_ctx(g_inst: _GenInst, gpg_ctx: GpgContext) -> GpgContextWExtInfo:
        if g_inst.w_min_dirs:
            create_and_assign_proper_permissions_to_gpg_home_dir(
                **gpg_ctx.as_proc_dict())
        else:
            create_and_assign_proper_permissions_to_user_home_dir(
                gpg_ctx.proc.home_dir.parent)

        for sid in g_inst.secret_ids:
            create_gpg_secret_identity(
                sid.email, sid.user_name, gpg_ctx.auth, proc=gpg_ctx.proc)

        return _load_fix_ctx(gpg_ctx)

    fix = GpgInitialFixture(
        *[gen_ctx(gi, ps) for (gi, ps) in zip(
            ginsts, ctxs.__dict__.values())]
    )

    ctx = fix.i_ie
    in_ctxs = [c for c in fix.__dict__.values() if c is not ctx]
    import_pub_key_for_all_sids_in_ctxs(ctx, in_ctxs)

    return load_gpg_initial_fixture(homes_root_dir)
