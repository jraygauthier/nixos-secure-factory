import pytest
import logging
from _pytest.tmpdir import TempPathFactory
from pathlib import Path

from nsft_pgp_utils.encrypt import encrypt_file_to_gpg_file
from nsft_pgp_utils.decrypt import decrypt_gpg_file_to_file
from nsft_system_utils.file import write_text_file_content, read_text_file_content

from test_lib.gpg_ctx_fixture_gen import GpgEncryptDecryptBasicFixture


@pytest.fixture
def tmp_enc_dec_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("enc_dec_dir")


def test_gpg_encrypt_decrypt_file_gpg(
        gpg_encrypt_decrypt_basic: GpgEncryptDecryptBasicFixture,
        tmp_enc_dec_dir: Path) -> None:
    fix = gpg_encrypt_decrypt_basic

    ori_file = tmp_enc_dec_dir.joinpath("file.txt")

    ori_file_content = [
        "Line1"
        "Line2"
    ]

    write_text_file_content(ori_file, ori_file_content)

    logging.info("encrypt_file_to_gpg_file")
    gpg_b64_file = encrypt_file_to_gpg_file(
        ori_file,
        tmp_enc_dec_dir.joinpath("file.txt.b64.gpg"),
        pre_encode_to_b64=False,
        recipients=map(lambda x: x.fpr, fix.e_e.keys.all),
        **fix.e_e.as_proc_dict()
    )

    logging.info("decrypt_gpg_file_to_file")
    dec_file = decrypt_gpg_file_to_file(
        gpg_b64_file,
        tmp_enc_dec_dir.joinpath("decrypted-file.txt"),
        post_decode_from_b64=False,
        **fix.d_a.as_proc_auth_dict()
    )

    dec_file_content = read_text_file_content(dec_file)

    assert ori_file_content == dec_file_content


def test_gpg_encrypt_decrypt_file_b64_gpg(
        gpg_encrypt_decrypt_basic: GpgEncryptDecryptBasicFixture,
        tmp_enc_dec_dir: Path) -> None:
    fix = gpg_encrypt_decrypt_basic

    ori_file = tmp_enc_dec_dir.joinpath("file.txt")

    ori_file_content = [
        "Line1"
        "Line2"
    ]

    write_text_file_content(ori_file, ori_file_content)

    logging.info("encrypt_file_to_gpg_file")
    gpg_b64_file = encrypt_file_to_gpg_file(
        ori_file,
        tmp_enc_dec_dir.joinpath("file.txt.b64.gpg"),
        pre_encode_to_b64=True,
        recipients=map(lambda x: x.fpr, fix.e_e.keys.all),
        **fix.e_e.as_proc_dict()
    )

    logging.info("decrypt_gpg_file_to_file")
    dec_file = decrypt_gpg_file_to_file(
        gpg_b64_file,
        tmp_enc_dec_dir.joinpath("decrypted-file.txt"),
        post_decode_from_b64=True,
        **fix.d_a.as_proc_auth_dict()
    )

    dec_file_content = read_text_file_content(dec_file)

    assert ori_file_content == dec_file_content
