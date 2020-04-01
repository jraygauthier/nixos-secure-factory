import shutil
from pathlib import Path
from typing import Callable, Optional, TypeVar

from nsft_cache_utils.dir import (OptPyTestFixtureRequestT,
                                  create_dir_content_cached_from_pytest)
from nsft_pgp_utils.ctx_auth_types import GpgAuthContext
from nsft_pgp_utils.ctx_gen_types import (
    GpgContextGenInfo, GpgContextWGenInfo, GpgKeyGenInfo,
    mk_gpg_ctx_w_gen_info_for_user_home_dir)
from nsft_pgp_utils.ctx_proc_types import mk_gpg_proc_ctx_for_user_home_dir
from nsft_pgp_utils.ctx_types import GpgContextWExtInfo
from nsft_pgp_utils.fixture_encrypt_decrypt import (
    GpgEncryptDecryptBasicFixture, generate_gpg_encrypt_decrypt_basic_fixture,
    load_gpg_encrypt_decrypt_basic_fixture)
from nsft_pgp_utils.fixture_initial import (GpgInitialFixture,
                                            generate_gpg_initial_fixture,
                                            load_gpg_initial_fixture)
from nsft_pgp_utils.home_dir import (
    create_and_assign_proper_permissions_to_gpg_home_dir,
    create_and_assign_proper_permissions_to_user_home_dir)
from nsft_pgp_utils.query import query_gpg_context_w_ext_info
from nsft_pgp_utils.secret_id import create_gpg_secret_identity

# We had the following trouble with those files during sandboxed copy of the gpg home
# directory:
# ```
# shutil.Error: .. "[Errno 6] No such device or address: '/path/to/.gnupg/S.gpg-agent
# ```
#
# This is why we need to ignore these files.
ignore_copy_for_gpg_home_dir = shutil.ignore_patterns(
    "S.gpg-agent", "S.gpg-agent.*", "S.scdaemon")

_LoadDirContentRetT = TypeVar('_LoadDirContentRetT')


def _create_dir_content_cached(
        dir: Path,
        generate_dir_content_fn: Callable[[Path], _LoadDirContentRetT],
        request: OptPyTestFixtureRequestT,
        load_dir_content_fn: Optional[Callable[[Path], _LoadDirContentRetT]] = None,
) -> _LoadDirContentRetT:
    stale_after_s = None
    return create_dir_content_cached_from_pytest(
        Path(__file__),
        dir,
        generate_dir_content_fn,
        request=request,
        stale_after_s=stale_after_s,
        copy_ignore_fn=ignore_copy_for_gpg_home_dir,
        load_dir_content_fn=load_dir_content_fn
    )


def generate_gpg_ctx_empty_no_dirs(home_dir: Path) -> GpgContextWGenInfo:
    create_and_assign_proper_permissions_to_user_home_dir(home_dir)

    return GpgContextWGenInfo(
        proc=mk_gpg_proc_ctx_for_user_home_dir(home_dir),
        auth=GpgAuthContext(passphrase=""),
        gen_info=GpgContextGenInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_no_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    return generate_gpg_ctx_empty_no_dirs(home_dir)


def generate_gpg_ctx_empty_minimal_dirs(home_dir: Path) -> GpgContextWGenInfo:
    proc = mk_gpg_proc_ctx_for_user_home_dir(home_dir)
    create_and_assign_proper_permissions_to_gpg_home_dir(proc=proc)
    return GpgContextWGenInfo(
        proc=proc,
        auth=GpgAuthContext(passphrase=""),
        gen_info=GpgContextGenInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_minimal_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    return generate_gpg_ctx_empty_minimal_dirs(home_dir)


def _generate_gpg_ctx_w_gen_info_from_gen_info(
        home_dir: Path, info: GpgContextGenInfo) -> GpgContextWGenInfo:
    gpg_ctx = mk_gpg_ctx_w_gen_info_for_user_home_dir(home_dir, info)

    for k_info in gpg_ctx.gen_info.secret_keys:
        create_gpg_secret_identity(
            k_info.email, k_info.user_name, gpg_ctx.auth, proc=gpg_ctx.proc)
    return gpg_ctx


def _generate_gpg_ctx_w_info_from_gen_info(
        home_dir: Path, info: GpgContextGenInfo) -> GpgContextWExtInfo:
    gpg_ctx = _generate_gpg_ctx_w_gen_info_from_gen_info(home_dir, info)
    return query_gpg_context_w_ext_info(auth=gpg_ctx.auth, proc=gpg_ctx.proc)


def get_gpg_ctx_w_secret_id_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=[
            GpgKeyGenInfo(
                user_name="MyNameSingle MyFamilyName",
                email="myusername-single@domain.com"
            )
        ]
    )


def generate_gpg_ctx_w_secret_id(home_dir: Path) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_w_gen_info_from_gen_info(
        home_dir, get_gpg_ctx_w_secret_id_info())


def generate_gpg_ctx_w_secret_id_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    _create_dir_content_cached(home_dir, generate_gpg_ctx_w_secret_id, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(
        home_dir, get_gpg_ctx_w_secret_id_info())


def get_gpg_ctx_w_2_distinct_secret_ids_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=[
            GpgKeyGenInfo(
                user_name="MyNameMan MyFamilyName",
                email="myusername-man@domain.com"
            ),
            GpgKeyGenInfo(
                user_name="MyNameWife MyFamilyName",
                email="myusername-wife@domain.com"
            )
        ]
    )


def generate_gpg_ctx_w_2_distinct_secret_ids(home_dir: Path) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_w_gen_info_from_gen_info(
        home_dir, get_gpg_ctx_w_2_distinct_secret_ids_info())


def generate_gpg_ctx_w_2_distinct_secret_ids_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    _create_dir_content_cached(
        home_dir, generate_gpg_ctx_w_2_distinct_secret_ids, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(
        home_dir, get_gpg_ctx_w_2_distinct_secret_ids_info())


def get_gpg_ctx_w_2_same_user_secret_ids_info() -> GpgContextGenInfo:
    return GpgContextGenInfo(
        secret_keys=([
            GpgKeyGenInfo(
                user_name="MyNameTwin MyFamilyName",
                email="myusername-twin@domain.com"
            )
        ] * 2)
    )


def generate_gpg_ctx_w_2_same_user_secret_ids(home_dir: Path) -> GpgContextWGenInfo:
    return _generate_gpg_ctx_w_gen_info_from_gen_info(
        home_dir, get_gpg_ctx_w_2_same_user_secret_ids_info())


def generate_gpg_ctx_w_2_same_user_secret_ids_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    _create_dir_content_cached(
        home_dir, generate_gpg_ctx_w_2_same_user_secret_ids, request)
    return mk_gpg_ctx_w_gen_info_for_user_home_dir(
        home_dir, get_gpg_ctx_w_2_same_user_secret_ids_info())


def generate_gpg_initial_fixture_cached(
        homes_root_dir: Path, request: OptPyTestFixtureRequestT = None
) -> GpgInitialFixture:
    return _create_dir_content_cached(
        homes_root_dir,
        generate_gpg_initial_fixture,
        request, load_gpg_initial_fixture)


def generate_gpg_encrypt_decrypt_basic_fixture_cached(
        homes_root_dir: Path, request: OptPyTestFixtureRequestT = None
) -> GpgEncryptDecryptBasicFixture:
    return _create_dir_content_cached(
        homes_root_dir,
        generate_gpg_encrypt_decrypt_basic_fixture,
        request, load_gpg_encrypt_decrypt_basic_fixture)
