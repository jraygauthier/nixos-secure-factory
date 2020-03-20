import logging
from pathlib import Path

from nsft_cache_utils.dir import PyTestFixtureRequestT
from test_lib.gpg_ctx_fixture_gen import (
    generate_gpg_encrypt_decrypt_basic_fixture_cached,
)


def test_generate_gpg_encrypt_decrypt_basic_fixture(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir: Path) -> None:
    fixture = generate_gpg_encrypt_decrypt_basic_fixture_cached(
        tmp_root_homes_dir, request)

    # Each of the 3 encrypter decrypter contexts knows of all other contexts're
    # public keys.
    for ck, c in fixture.__dict__.items():
        logging.info(f"ck: {ck}")
        assert 1 == len(c.keys.secret)
        assert 2 == len(c.keys.public)
