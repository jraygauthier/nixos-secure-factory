from dataclasses import dataclass
from pathlib import Path
from typing import Tuple

from .ctx_gen_types import (
    GpgContextGenInfo,
    GpgKeyGenInfo
)
from .ctx_types import GpgContextWExtInfo, GpgContext, mk_gpg_ctx_for_user_home_dir
from .secret_id import create_gpg_secret_identity
from .query import query_gpg_context_w_ext_info
from ._fixture_gen_tools import import_pub_key_for_all_sids_in_ctxs


@dataclass
class _GpgEncryptDecryptBasicGenInfo:
    d_a: GpgContextGenInfo
    d_b: GpgContextGenInfo
    e_e: GpgContextGenInfo


def _mk_gpg_encrypt_decrypt_basic_gen_info() -> _GpgEncryptDecryptBasicGenInfo:
    def _mk_gen_info(in_fn_and_elp: Tuple[str, str]) -> GpgContextGenInfo:
        first_name, email_local_part = in_fn_and_elp

        return GpgContextGenInfo(
            secret_keys=[
                GpgKeyGenInfo(
                    user_name=f"{first_name} Secrets",
                    email=f"{email_local_part}@secrets.com"
                )
            ]
        )

    return _GpgEncryptDecryptBasicGenInfo(
        *map(_mk_gen_info, [
            ("DecrypterA", "decrypter-a"),
            ("DecrypterB", "decrypter-b"),
            ("EncrypterE", "encrypter-e"),
        ])
    )


@dataclass
class _GpgUserPaths:
    home_dir: Path
    # Other paths here if useful at some point.


def _mk_gpg_user_paths(home_dir: Path) -> _GpgUserPaths:
    return _GpgUserPaths(home_dir)


@dataclass
class _GpgEncryptDecryptBasicPaths:
    d_a: _GpgUserPaths
    d_b: _GpgUserPaths
    e_e: _GpgUserPaths


def mk_gpg_encrypt_decrypt_basic_paths(
        homes_root_dir: Path) -> _GpgEncryptDecryptBasicPaths:

    def mk_home_dir(user_name: str) -> _GpgUserPaths:
        return _mk_gpg_user_paths(homes_root_dir.joinpath(user_name))

    return _GpgEncryptDecryptBasicPaths(
        *map(mk_home_dir, [
            "decrypter-a",
            "decrypter-b",
            "encrypter-e"
        ])
    )


@dataclass
class _GpgEncryptDecryptBasicCtxs:
    d_a: GpgContext
    d_b: GpgContext
    e_e: GpgContext


def _mk_gpg_encrypt_decrypt_basic_ctxs(
        homes_root_dir: Path) -> _GpgEncryptDecryptBasicCtxs:
    ctxs = map(
        lambda ps: mk_gpg_ctx_for_user_home_dir(ps.home_dir),
        mk_gpg_encrypt_decrypt_basic_paths(homes_root_dir).__dict__.values())

    return _GpgEncryptDecryptBasicCtxs(
        *ctxs
    )


@dataclass
class GpgEncryptDecryptBasicFixture:
    #
    # Part of the trust network (they all know and trust each other fully).
    #
    # This is the ideal case / happiest situation possible.
    #

    # Decrypter contexes
    d_a: GpgContextWExtInfo
    d_b: GpgContextWExtInfo
    # Encrypter contexes
    e_e: GpgContextWExtInfo


def load_gpg_encrypt_decrypt_basic_fixture(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicFixture:

    ctxs = _mk_gpg_encrypt_decrypt_basic_ctxs(homes_root_dir)
    return GpgEncryptDecryptBasicFixture(
        *[query_gpg_context_w_ext_info(**ctx.as_proc_auth_dict())
            for ctx in ctxs.__dict__.values()]
    )


def generate_gpg_encrypt_decrypt_basic_fixture(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicFixture:

    gen_info = _mk_gpg_encrypt_decrypt_basic_gen_info()
    ctxs = _mk_gpg_encrypt_decrypt_basic_ctxs(homes_root_dir)

    def gen_ctx(g_info: GpgContextGenInfo, gpg_ctx: GpgContext) -> GpgContextWExtInfo:
        for k_info in g_info.secret_keys:
            create_gpg_secret_identity(
                k_info.email, k_info.user_name, gpg_ctx.auth, proc=gpg_ctx.proc)
        return query_gpg_context_w_ext_info(**gpg_ctx.as_proc_auth_dict())

    fix = GpgEncryptDecryptBasicFixture(
        *[gen_ctx(gi, ps) for (gi, ps) in zip(
            gen_info.__dict__.values(), ctxs.__dict__.values())]
    )

    for ctx_i, ctx in enumerate(fix.__dict__.values()):
        in_ctxs = [c for ci, c in enumerate(fix.__dict__.values()) if ci != ctx_i]
        import_pub_key_for_all_sids_in_ctxs(ctx, in_ctxs)

    return load_gpg_encrypt_decrypt_basic_fixture(homes_root_dir)
