
import os

import pytest
from nsft_pgp_utils.process import (
    GpgProcContext,
    GpgProcContextExp,
    ensure_gpg_proc_ctx,
)
from nsft_pgp_utils.secret_id import create_gpg_secret_identity
from nsft_system_utils.file import write_text_file_content


def _mk_tmp_gpg_ctx(home_dir: str) -> GpgProcContextExp:
    gpg_home_dir = os.path.join(home_dir, ".gnupg")
    email = "user-gpg-home@tmp-dir.com"
    user_name = "UserGpgHome TempDir"

    proc = ensure_gpg_proc_ctx(GpgProcContext(exe="gpg", home_dir=gpg_home_dir))
    create_gpg_secret_identity(
        email, user_name,
        passphrase="",
        proc=proc)

    return proc


@pytest.fixture(scope="session")
def tmp_decrypter_gpg_ctx(tmpdir_factory) -> GpgProcContextExp:
    home_dir = tmpdir_factory.mktemp("encrypter-home-user")
    return _mk_tmp_gpg_ctx(home_dir)


@pytest.fixture(scope="session")
def tmp_decrypter_public_key_file(tmp_decrypter_gpg_ctx) -> str:
    return None


@pytest.fixture(scope="session")
def tmp_encrypter_gpg_ctx(
        tmpdir_factory, tmp_decrypter_public_key_file) -> GpgProcContextExp:

    home_dir = tmpdir_factory.mktemp("encrypter-home-user")
    proc = _mk_tmp_gpg_ctx(home_dir)



@pytest.fixture(scope="module")
def src_pgp_tmp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("src_pgp")


@pytest.fixture(scope="module")
def src_pgp_tmp_dir_w_dummy_files(src_pgp_tmp_dir):
    fn = src_pgp_tmp_dir.join("dummy.txt")
    write_text_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = src_pgp_tmp_dir.join("dummy-ro.txt")
    write_text_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])

    dir = src_pgp_tmp_dir.join("dummy-dir")
    os.mkdir(dir, mode=0o555)

    dir_ro = src_pgp_tmp_dir.join("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    # Make these files and dirs ro to flag manip errors.
    os.chmod(fn, mode=0o444)
    os.chmod(fn_ro, mode=0o444)
    os.chmod(src_pgp_tmp_dir, mode=0o555)
    return src_pgp_tmp_dir


@pytest.fixture(scope="function")
def tgt_pgp_tmp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("tgt_pgp")


@pytest.fixture(scope="function")
def tgt_pgp_tmp_dir_w_dummy_files(tgt_pgp_tmp_dir):
    fn = tgt_pgp_tmp_dir.join("dummy.txt")
    write_text_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = tgt_pgp_tmp_dir.join("dummy-ro.txt")
    write_text_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])
    os.chmod(fn_ro, mode=0o444)

    dir = tgt_pgp_tmp_dir.join("dummy-dir")
    os.mkdir(dir)

    dir_ro = tgt_pgp_tmp_dir.join("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    return tgt_pgp_tmp_dir
