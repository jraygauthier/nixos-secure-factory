import shutil
from pathlib import Path
from typing import Callable, TypeVar, Optional

from nsft_cache_utils.dir import (
    OptPyTestFixtureRequestT,
    create_dir_content_cached_from_pytest,
)
from nsft_pgp_utils.ctx_auth_types import GpgAuthContext
from nsft_pgp_utils.ctx_gen_types import (
    GpgContextGenInfo,
    GpgContextWGenInfo
)
from nsft_pgp_utils.ctx_proc_types import mk_gpg_proc_ctx_for_user_home_dir
from nsft_pgp_utils.fixture_encrypt_decrypt import (
    generate_gpg_encrypt_decrypt_basic_fixture,
    load_gpg_encrypt_decrypt_basic_fixture,
    GpgEncryptDecryptBasicFixture
)
from nsft_pgp_utils.home_dir import (
    create_and_assign_proper_permissions_to_gpg_home_dir,
    create_and_assign_proper_permissions_to_user_home_dir,
)

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


def generate_gpg_encrypt_decrypt_basic_fixture_cached(
        homes_root_dir: Path, request: OptPyTestFixtureRequestT = None
) -> GpgEncryptDecryptBasicFixture:
    return _create_dir_content_cached(
        homes_root_dir,
        generate_gpg_encrypt_decrypt_basic_fixture,
        request, load_gpg_encrypt_decrypt_basic_fixture)
