
import os
from pathlib import Path

import pytest
from _pytest.tmpdir import TempPathFactory

from nsft_cache_utils.dir import PyTestFixtureRequestT

from nsft_system_utils.file import write_text_file_content
from nsft_pgp_utils.fixture_initial import copy_gpg_initial_fixture
from test_lib.gpg_ctx_fixture_gen import (
    GpgEncryptDecryptBasicFixture,
    GpgInitialFixture,
    WhoIToCtxMapping,
    generate_gpg_encrypt_decrypt_basic_fixture_cached,
    generate_gpg_initial_fixture_cached,
    get_i_fix_ctx_for,
    generate_gpg_initial_fixture_encrypted_exports,
    generate_gpg_encrypted_files_basic
)


@pytest.fixture(scope="module")
def tmp_root_homes_dir_enc_dec_ro(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("root-homes-enc-dec-ro")


@pytest.fixture(scope="module")
def gpg_encrypt_decrypt_basic_ro(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir_enc_dec_ro: Path
) -> GpgEncryptDecryptBasicFixture:
    # TODO: It is however not possible to mark gpg home dir as ro.
    # We will assume that uses of this fixture **do not** mutate
    # the gpg home dir.
    return generate_gpg_encrypt_decrypt_basic_fixture_cached(
        tmp_root_homes_dir_enc_dec_ro, request)


@pytest.fixture(scope="module")
def tmp_root_homes_dir_init_ro(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("root-homes-init-ro")


@pytest.fixture(scope="module")
def gpg_initial_ro(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir_init_ro: Path
) -> GpgInitialFixture:
    return generate_gpg_initial_fixture_cached(
        tmp_root_homes_dir_init_ro, request)


@pytest.fixture
def tmp_root_homes_dir_init(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("root-homes-init")


@pytest.fixture
def gpg_initial(
        gpg_initial_ro: GpgInitialFixture,
        tmp_root_homes_dir_init: Path
) -> GpgInitialFixture:

    return copy_gpg_initial_fixture(
        tmp_root_homes_dir_init, gpg_initial_ro)


@pytest.fixture(scope="module")
def src_pgp_tmp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("src-pgp")


@pytest.fixture(scope="module")
def src_pgp_decrypt_dir(
        src_pgp_tmp_dir: Path,
        gpg_encrypt_decrypt_basic_ro: GpgEncryptDecryptBasicFixture
) -> Path:
    return generate_gpg_encrypted_files_basic(
        src_pgp_tmp_dir, gpg_encrypt_decrypt_basic_ro)


@pytest.fixture(scope="function")
def tgt_pgp_tmp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("tgt_pgp")


@pytest.fixture(scope="function")
def tgt_pgp_decrypt_dir(tgt_pgp_tmp_dir: Path) -> Path:
    tmp_dir = tgt_pgp_tmp_dir

    def write_dummy_files_to(d: Path):
        fn = d.joinpath("dummy.txt")
        dummy_content = [
            "Dummy linu1."
            "Dummy line2"
        ]
        write_text_file_content(fn, dummy_content)

        fn_ro = d.joinpath("dummy-ro.txt")
        write_text_file_content(fn_ro, dummy_content)
        os.chmod(fn_ro, mode=0o444)

    dir = tmp_dir.joinpath("dummy-dir")
    os.mkdir(dir)
    write_dummy_files_to(dir)

    dir_ro = tmp_dir.joinpath("dummy-dir-ro")
    os.mkdir(dir_ro)
    write_dummy_files_to(dir_ro)
    os.chmod(dir_ro, mode=0o555)

    return tmp_dir


@pytest.fixture(scope="module")
def src_gnupg_keyring_deploy_dir(
        src_pgp_tmp_dir: Path,
        gpg_initial_ro: GpgInitialFixture
) -> Path:
    return generate_gpg_initial_fixture_encrypted_exports(
        src_pgp_tmp_dir, gpg_initial_ro)


@pytest.fixture
def tgt_gnupg_keyring_deploy_who_to_ctx_map(
        gpg_initial: GpgInitialFixture
) -> WhoIToCtxMapping:
    return lambda who: get_i_fix_ctx_for(gpg_initial, who)
