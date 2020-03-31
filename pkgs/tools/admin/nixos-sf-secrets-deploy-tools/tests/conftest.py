
import os
import shutil
from pathlib import Path

import pytest
from _pytest.tmpdir import TempPathFactory

from nsft_cache_utils.dir import PyTestFixtureRequestT
from nsft_system_utils.file import write_text_file_content
from nsft_pgp_utils.encrypt import encrypt_file_to_gpg_file

from test_lib.gpg_ctx_fixture_gen import (
    GpgEncryptDecryptBasicFixture,
    generate_gpg_encrypt_decrypt_basic_fixture_cached,
)


@pytest.fixture(scope="module")
def tmp_root_homes_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("root_homes")


@pytest.fixture(scope="module")
def gpg_encrypt_decrypt_basic_ro(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir: Path
) -> GpgEncryptDecryptBasicFixture:
    # TODO: It is however not possible to mark gpg home dir as ro.
    # We will assume that uses of this fixture **do not** mutate
    # the gpg home dir.
    return generate_gpg_encrypt_decrypt_basic_fixture_cached(
        tmp_root_homes_dir, request)


@pytest.fixture(scope="module")
def src_pgp_tmp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("src_pgp")


@pytest.fixture(scope="module")
def src_pgp_decrypt_dir(
        src_pgp_tmp_dir: Path,
        gpg_encrypt_decrypt_basic_ro: GpgEncryptDecryptBasicFixture
) -> Path:
    fix = gpg_encrypt_decrypt_basic_ro
    tmp_dir = src_pgp_tmp_dir

    original_dir = tmp_dir.joinpath("original")
    os.mkdir(original_dir)

    original_file = original_dir.joinpath("file.txt")
    original_file_content = [
        "Line1",
        "Line2"
    ]

    write_text_file_content(original_file, original_file_content)

    original_file_no_ext = original_dir.joinpath("file")
    write_text_file_content(original_file_no_ext, original_file_content)

    # Make these files and dirs ro to flag manip errors.
    os.chmod(original_file, mode=0o444)
    os.chmod(original_dir, mode=0o555)

    enc_cases = [
        ("r-all", fix.e_e.keys.all),
        ("r-e", [fix.e_e.keys.secret[0]]),
        ("r-a", [fix.d_a.keys.secret[0]]),
        ("r-b", [fix.d_b.keys.secret[0]]),
        ("r-ab", [fix.d_a.keys.secret[0], fix.d_b.keys.secret[0]]),
    ]

    for c_id, c_rs in enc_cases:
        encrypted_dir = tmp_dir.joinpath(f"encrypted-{c_id}")
        os.mkdir(encrypted_dir)

        enc_gpg_b64_file = encrypt_file_to_gpg_file(
            original_file,
            encrypted_dir.joinpath("file.txt.b64.gpg"),
            pre_encode_to_b64=True,
            recipients=map(lambda x: x.fpr, c_rs),
            **fix.e_e.as_proc_dict()
        )

        enc_gpg_file = encrypt_file_to_gpg_file(
            original_file,
            encrypted_dir.joinpath("file.txt.gpg"),
            pre_encode_to_b64=False,
            recipients=map(lambda x: x.fpr, c_rs),
            **fix.e_e.as_proc_dict()
        )
        # Make these files and dirs ro to flag manip errors.
        os.chmod(enc_gpg_b64_file, mode=0o444)
        os.chmod(enc_gpg_file, mode=0o444)

        # Create some fraudulous files that impersonates other via their extensions.
        for s, rp in [
            (original_file, "fraud-txt-file-as.txt.gpg"),
            (original_file, "fraud-txt-file-as.txt.b64.gpg"),
            (enc_gpg_file, "fraud-txt-gpg-file-as.txt.b64.gpg"),
            (enc_gpg_b64_file, "fraud-txt-b64-gpg-file-as.txt.gpg")
        ]:
            op = encrypted_dir.joinpath(rp)
            shutil.copyfile(s, encrypted_dir.joinpath(rp))
            os.chmod(op, mode=0o444)

        # Create some faudulous dir impersonating encrypted files
        # Create some fraudulous files that impersonates other via their extensions.
        for s, rp in [
            (original_file, "fraud-dir-as.txt.gpg"),
            (original_file, "fraud-dir-as.txt.b64.gpg"),
        ]:
            op = encrypted_dir.joinpath(rp)
            os.mkdir(op, mode=0o555)

        shutil.copyfile(
            enc_gpg_b64_file, encrypted_dir.joinpath("file-txt-b64-gpg-no-ext"))
        shutil.copyfile(
            enc_gpg_file, encrypted_dir.joinpath("file-txt-gpg-no-ext"))

        os.chmod(encrypted_dir, mode=0o555)

    return tmp_dir


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
