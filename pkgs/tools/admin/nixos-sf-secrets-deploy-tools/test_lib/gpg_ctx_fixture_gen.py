import shutil
from pathlib import Path
from typing import Any, Callable, List

from nsft_cache_utils.dir import (
    OptPyTestFixtureRequestT,
    create_dir_content_cached_from_pytest,
)

from nsft_pgp_utils.secret_id import create_gpg_secret_identity

from nsft_pgp_utils.ctx_gen_types import (
    GpgContextGenInfo,
    GpgContextWGenInfo,
    GpgKeyGenInfo,
    mk_gpg_ctx_w_gen_info_for_user_home_dir,
)

from nsft_pgp_utils.ctx_auth_types import GpgAuthContext
from nsft_pgp_utils.ctx_proc_types import mk_gpg_proc_ctx_for_user_home_dir

# We had the following trouble with those files during sandboxed copy of the gpg home
# directory:
# ```
# shutil.Error: .. "[Errno 6] No such device or address: '/path/to/.gnupg/S.gpg-agent
# ```
#
# This is why we need to ignore these files.
ignore_copy_for_gpg_home_dir = shutil.ignore_patterns("S.gpg-agent", "S.gpg-agent.*")


def _create_dir_content_cached(
        dir: Path,
        create_dir_content_fn: Callable[[Path], Any],
        request: OptPyTestFixtureRequestT
) -> None:
    stale_after_s = None
    create_dir_content_cached_from_pytest(
        Path(__file__),
        dir,
        create_dir_content_fn,
        request=request,
        stale_after_s=stale_after_s,
        copy_ignore_fn=ignore_copy_for_gpg_home_dir
    )


def generate_gpg_ctx_empty(home_dir: Path) -> GpgContextWGenInfo:
    return GpgContextWGenInfo(
        proc=mk_gpg_proc_ctx_for_user_home_dir(home_dir),
        auth=GpgAuthContext(passphrase=""),
        gen_info=GpgContextGenInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    return generate_gpg_ctx_empty(home_dir)


def _generate_gpg_ctx_from_info(
        home_dir: Path, info: GpgContextGenInfo) -> GpgContextWGenInfo:
    gpg_ctx = mk_gpg_ctx_w_gen_info_for_user_home_dir(home_dir, info)

    for k_info in gpg_ctx.gen_info.secret_keys:
        create_gpg_secret_identity(
            k_info.email, k_info.user_name, gpg_ctx.auth, proc=gpg_ctx.proc)
    return gpg_ctx


def get_gpg_ctx_decrypter_a_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=[
            GpgKeyGenInfo(
                user_name="DecrypterA Secrets",
                email="decrypter-a@secrets.com"
            )
        ]
    )


def generate_gpg_ctx_decrypter_a(home_dir: Path) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, generate_gpg_ctx_decrypter_a())


def generate_gpg_ctx_decrypter_a_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    _create_dir_content_cached(home_dir, generate_gpg_ctx_decrypter_a, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(home_dir, get_gpg_ctx_decrypter_a_info())


def get_gpg_ctx_decrypter_b_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=[
            GpgKeyGenInfo(
                user_name="DecrypterB Secrets",
                email="decrypter-b@secrets.com"
            )
        ]
    )


def generate_gpg_ctx_decrypter_b(home_dir: Path) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, get_gpg_ctx_decrypter_b_info())


def generate_gpg_ctx_decrypter_b_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    _create_dir_content_cached(home_dir, generate_gpg_ctx_decrypter_b, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(home_dir, get_gpg_ctx_decrypter_b_info())


def get_gpg_ctx_encrypter_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=[
            GpgKeyGenInfo(
                user_name="Encrypter Secrets",
                email="encrypter@secrets.com"
            )
        ]
    )


def generate_gpg_ctx_encrypter(
        home_dir: Path,
        decrypters_ctx: List[GpgContextWGenInfo]) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, get_gpg_ctx_encrypter_info())


def generate_gpg_ctx_encrypter_cached(
        home_dir: Path,
        decrypters_ctx: List[GpgContextWGenInfo],
        request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:

    def gen_dir(home_dir: Path) -> GpgContextWGenInfo:
        return generate_gpg_ctx_encrypter(home_dir, decrypters_ctx)

    _create_dir_content_cached(home_dir, gen_dir, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(home_dir, get_gpg_ctx_encrypter_info())
