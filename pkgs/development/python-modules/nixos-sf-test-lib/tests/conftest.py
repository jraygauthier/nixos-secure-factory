from pathlib import Path
from typing import Callable

import pytest
from _pytest.tmpdir import TempPathFactory

from nsft_cache_utils.dir import (OptPyTestFixtureRequestT,
                                  PyTestFixtureRequestT)
from nsft_system_utils.permissions import call_chmod
from test_lib.gpg_ctx_checks import (check_minimal_gpg_home_dir_empty,
                                     check_minimal_gpg_home_dir_w_secret_id)
from test_lib.gpg_ctx_fixture_gen import (
    GpgContextWGenInfo, generate_gpg_ctx_empty_minimal_dirs_cached,
    GpgEncryptDecryptBasicFixture,
    generate_gpg_ctx_empty_no_dirs_cached,
    generate_gpg_ctx_w_2_distinct_secret_ids_cached,
    generate_gpg_ctx_w_2_same_user_secret_ids_cached,
    generate_gpg_ctx_w_secret_id_cached,
    generate_gpg_encrypt_decrypt_basic_fixture_cached)

_GpgCtxGenFnT = Callable[[Path, OptPyTestFixtureRequestT], GpgContextWGenInfo]


@pytest.fixture
def tmp_root_homes_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("root_homes")


@pytest.fixture
def tmp_user_home_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("home_user")


@pytest.fixture
def tmp_export_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("export_dir")


def _mk_gpg_ctx_w_info_fixture_no_checks(
        gen_fn: _GpgCtxGenFnT,
        tmp_factory: TempPathFactory,
        request: OptPyTestFixtureRequestT
) -> GpgContextWGenInfo:
    home_dir = tmp_factory.mktemp("home_user")
    gpg_ctx = gen_fn(home_dir, request)
    return gpg_ctx


def _mk_gpg_ctx_w_info_fixture(
        gen_fn: _GpgCtxGenFnT,
        tmp_factory: TempPathFactory,
        request: OptPyTestFixtureRequestT
) -> GpgContextWGenInfo:
    gpg_ctx = _mk_gpg_ctx_w_info_fixture_no_checks(
        gen_fn, tmp_factory, request)
    check_minimal_gpg_home_dir_w_secret_id(gpg_ctx.proc)
    return gpg_ctx


def _mk_ro_gpg_ctx_w_info_fixture(
        gen_fn: _GpgCtxGenFnT,
        tmp_factory: TempPathFactory,
        request: OptPyTestFixtureRequestT
) -> GpgContextWGenInfo:
    gpg_ctx = _mk_gpg_ctx_w_info_fixture(gen_fn, tmp_factory, request)
    call_chmod(gpg_ctx.proc.home_dir, "a-w", recursive=True)
    return gpg_ctx


@pytest.fixture
def gpg_ctx_empty_no_dirs(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    gpg_ctx = _mk_gpg_ctx_w_info_fixture_no_checks(
        generate_gpg_ctx_empty_no_dirs_cached,
        tmp_path_factory, request)
    return gpg_ctx


@pytest.fixture
def gpg_ctx_empty_minimal_dirs(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    gpg_ctx = _mk_gpg_ctx_w_info_fixture_no_checks(
        generate_gpg_ctx_empty_minimal_dirs_cached,
        tmp_path_factory, request)
    check_minimal_gpg_home_dir_empty(gpg_ctx.proc)
    return gpg_ctx


@pytest.fixture(scope="session")
def gpg_ctx_w_secret_id_ro(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    return _mk_ro_gpg_ctx_w_info_fixture(
        generate_gpg_ctx_w_secret_id_cached,
        tmp_path_factory, request)


@pytest.fixture
def gpg_ctx_w_secret_id(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    return _mk_gpg_ctx_w_info_fixture(
        generate_gpg_ctx_w_secret_id_cached,
        tmp_path_factory, request)


@pytest.fixture
def gpg_ctx_w_2_distinct_secret_ids(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    return _mk_gpg_ctx_w_info_fixture(
        generate_gpg_ctx_w_2_distinct_secret_ids_cached,
        tmp_path_factory, request)


@pytest.fixture
def gpg_ctx_w_2_same_user_secret_ids(
        request: PyTestFixtureRequestT,
        tmp_path_factory: TempPathFactory) -> GpgContextWGenInfo:
    return _mk_gpg_ctx_w_info_fixture(
        generate_gpg_ctx_w_2_same_user_secret_ids_cached,
        tmp_path_factory, request)


@pytest.fixture
def gpg_encrypt_decrypt_basic(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir: Path
) -> GpgEncryptDecryptBasicFixture:
    return generate_gpg_encrypt_decrypt_basic_fixture_cached(
        tmp_root_homes_dir, request)
