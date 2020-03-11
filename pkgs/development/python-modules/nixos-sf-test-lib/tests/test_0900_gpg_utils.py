import os

import pytest

from nsft_pgp_utils.home_dir import create_and_assign_proper_permissions_to_gpg_home_dir
from nsft_pgp_utils.process import GpgContextWExpandedPaths, ensure_gpg_context
from nsft_pgp_utils.secret_id import create_gpg_master_identity_with_signing_subkey


@pytest.fixture(scope="session")
def user_home_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("home_user")


@pytest.fixture(scope="session")
def encrypter_home_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("home_encrypter")


@pytest.fixture(scope="session")
def decrypter_home_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("home_decrypter")


def _mk_gpg_ctx_for(user_home_dir: str) -> GpgContextWExpandedPaths:
    gpg_home_dir = os.path.join(user_home_dir, ".gnupg")
    return ensure_gpg_context((None, gpg_home_dir))


@pytest.mark.skip(reason="")
def test_create_and_assign_proper_permissions_to_gpg_home_dir(
        encrypter_home_dir) -> None:
    gpg_ctx = _mk_gpg_ctx_for(encrypter_home_dir)
    create_and_assign_proper_permissions_to_gpg_home_dir(gpg_ctx=gpg_ctx)

    assert os.path.exists(gpg_ctx.path)
    # assert get_file_uid(gpg_ctx.path)


@pytest.mark.skip(reason="")
def test_create(gpg_encrypter_home_empty) -> None:
    email = "myusername@domain.com"
    user_name = "MyName MyFamilyName"
    gpg_ctx = (None, gpg_encrypter_home_empty)
    create_gpg_master_identity_with_signing_subkey(
        email, user_name, "", gpg_ctx=gpg_ctx)

    create_and_assign_proper_permissions_to_gpg_home_dir(
        gpg_ctx=gpg_ctx)
