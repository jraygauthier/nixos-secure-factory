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
from .io_export import export_gpg_public_key_to_text
from .io_import import import_gpg_key_text
from .trust_types import GpgOwnerTrust
from .trust import sign_and_trust_gpg_key


@dataclass
class GpgEncryptDecryptBasicGenInfo:
    d_a: GpgContextGenInfo
    d_b: GpgContextGenInfo
    e_e: GpgContextGenInfo


def mk_gpg_encrypt_decrypt_basic_gen_info() -> GpgEncryptDecryptBasicGenInfo:
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

    return GpgEncryptDecryptBasicGenInfo(
        *map(_mk_gen_info, [
            ("DecrypterA", "decrypter-a"),
            ("DecrypterB", "decrypter-b"),
            ("EncrypterE", "encrypter-e"),
        ])
    )


@dataclass
class GpgUserPaths:
    home_dir: Path


def mk_gpg_user_paths(home_dir: Path) -> GpgUserPaths:
    return GpgUserPaths(home_dir)


@dataclass
class GpgEncryptDecryptBasicPaths:
    d_a: GpgUserPaths
    d_b: GpgUserPaths
    e_e: GpgUserPaths


def mk_gpg_encrypt_decrypt_basic_paths(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicPaths:

    def mk_home_dir(user_name: str) -> GpgUserPaths:
        return mk_gpg_user_paths(homes_root_dir.joinpath(user_name))

    return GpgEncryptDecryptBasicPaths(
        *map(mk_home_dir, [
            "decrypter_a",
            "decrypter_b",
            "encrypter_e"
        ])
    )


@dataclass
class GpgEncryptDecryptBasicCtxs:
    d_a: GpgContext
    d_b: GpgContext
    e_e: GpgContext


def mk_gpg_encrypt_decrypt_basic_ctx(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicCtxs:
    ctxs = map(
        lambda ps: mk_gpg_ctx_for_user_home_dir(ps.home_dir),
        mk_gpg_encrypt_decrypt_basic_paths(homes_root_dir).__dict__.values())

    return GpgEncryptDecryptBasicCtxs(
        *ctxs
    )


@dataclass
class GpgEncryptDecryptBasicFixture:
    d_a: GpgContextWExtInfo
    d_b: GpgContextWExtInfo
    e_e: GpgContextWExtInfo


def load_gpg_encrypt_decrypt_basic_fixture(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicFixture:

    ctxs = mk_gpg_encrypt_decrypt_basic_ctx(homes_root_dir)
    return GpgEncryptDecryptBasicFixture(
        *[query_gpg_context_w_ext_info(**ctx.as_proc_auth_dict())
            for ctx in ctxs.__dict__.values()]
    )


def generate_gpg_encrypt_decrypt_basic_fixture(
        homes_root_dir: Path) -> GpgEncryptDecryptBasicFixture:

    gen_info = mk_gpg_encrypt_decrypt_basic_gen_info()
    ctxs = mk_gpg_encrypt_decrypt_basic_ctx(homes_root_dir)

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

        for in_ctx in in_ctxs:
            for sk in in_ctx.keys.secret:
                exp_str = export_gpg_public_key_to_text(
                    sk.fpr, **in_ctx.as_proc_auth_dict())
                import_gpg_key_text(exp_str, **ctx.as_proc_dict())
                # The following is essential as otherwise, file encyption will fail
                # with this key as a recipient.
                sign_and_trust_gpg_key(
                    sk.fpr, GpgOwnerTrust.Fully,
                    **ctx.as_proc_auth_dict())

    return load_gpg_encrypt_decrypt_basic_fixture(homes_root_dir)
