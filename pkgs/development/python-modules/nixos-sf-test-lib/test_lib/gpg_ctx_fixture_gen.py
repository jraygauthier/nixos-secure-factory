import shutil
from pathlib import Path
from typing import Any, Callable

from nsft_cache_utils.dir import (
    OptPyTestFixtureRequestT,
    create_dir_content_cached_from_pytest,
)
from nsft_pgp_utils.home_dir import (
    create_and_assign_proper_permissions_to_gpg_home_dir,
    create_and_assign_proper_permissions_to_user_home_dir,
)
from nsft_pgp_utils.secret_id import create_gpg_secret_identity

from .gpg_ctx import (
    GpgAuthContext,
    GpgContextInfo,
    GpgContextWInfo,
    GpgKeyInfo,
    mk_gpg_ctx_w_info,
    mk_gpg_proc_ctx_for,
)

# We add the following trouble with those files during sandboxed copy of the gpg home
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


def generate_gpg_ctx_empty_no_dirs(home_dir: Path) -> GpgContextWInfo:
    create_and_assign_proper_permissions_to_user_home_dir(home_dir)

    return GpgContextWInfo(
        proc=mk_gpg_proc_ctx_for(home_dir),
        auth=GpgAuthContext(passphrase=""),
        info=GpgContextInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_no_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWInfo:
    return generate_gpg_ctx_empty_no_dirs(home_dir)


def generate_gpg_ctx_empty_minimal_dirs(home_dir: Path) -> GpgContextWInfo:
    proc_ctx = mk_gpg_proc_ctx_for(home_dir)
    create_and_assign_proper_permissions_to_gpg_home_dir(proc_ctx=proc_ctx)
    return GpgContextWInfo(
        proc=proc_ctx,
        auth=GpgAuthContext(passphrase=""),
        info=GpgContextInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_minimal_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWInfo:
    return generate_gpg_ctx_empty_minimal_dirs(home_dir)


def _generate_gpg_ctx_from_info(
        home_dir: Path, info: GpgContextInfo) -> GpgContextWInfo:
    gpg_ctx = mk_gpg_ctx_w_info(home_dir, info)

    for k_info in gpg_ctx.info.secret_keys:
        create_gpg_secret_identity(
            k_info.email, k_info.user_name, gpg_ctx.auth, proc_ctx=gpg_ctx.proc)
    return gpg_ctx


def get_gpg_ctx_w_secret_id_info() -> GpgContextInfo:
    return GpgContextInfo(
        secret_keys=[
            GpgKeyInfo(
                user_name="MyName MyFamilyName",
                email="myusername@domain.com"
            )
        ]
    )


def generate_gpg_ctx_w_secret_id(home_dir: Path) -> GpgContextWInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, get_gpg_ctx_w_secret_id_info())


def generate_gpg_ctx_w_secret_id_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWInfo:
    _create_dir_content_cached(home_dir, generate_gpg_ctx_w_secret_id, request)
    return mk_gpg_ctx_w_info(home_dir, get_gpg_ctx_w_secret_id_info())


def get_gpg_ctx_w_2_distinct_secret_ids_info() -> GpgContextInfo:
    return GpgContextInfo(
        secret_keys=[
            GpgKeyInfo(
                user_name="MyName MyFamilyName",
                email="myusername@domain.com"
            ),
            GpgKeyInfo(
                user_name="My2ndName MyFamilyName",
                email="my2ndusername@domain.com"
            )
        ]
    )


def generate_gpg_ctx_w_2_distinct_secret_ids(home_dir: Path) -> GpgContextWInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, get_gpg_ctx_w_2_distinct_secret_ids_info())


def generate_gpg_ctx_w_2_distinct_secret_ids_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWInfo:
    _create_dir_content_cached(
        home_dir, generate_gpg_ctx_w_2_distinct_secret_ids, request)
    return mk_gpg_ctx_w_info(home_dir, get_gpg_ctx_w_2_distinct_secret_ids_info())


def get_gpg_ctx_w_2_same_user_secret_ids_info() -> GpgContextInfo:
    return GpgContextInfo(
        secret_keys=([
            GpgKeyInfo(
                user_name="MyName MyFamilyName",
                email="myusername@domain.com"
            )
        ] * 2)
    )


def generate_gpg_ctx_w_2_same_user_secret_ids(home_dir: Path) -> GpgContextWInfo:
    return _generate_gpg_ctx_from_info(
        home_dir, get_gpg_ctx_w_2_same_user_secret_ids_info())


def generate_gpg_ctx_w_2_same_user_secret_ids_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWInfo:
    _create_dir_content_cached(
        home_dir, generate_gpg_ctx_w_2_same_user_secret_ids, request)
    return mk_gpg_ctx_w_info(home_dir, get_gpg_ctx_w_2_same_user_secret_ids_info())
