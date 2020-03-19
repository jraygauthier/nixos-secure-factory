import logging
from pathlib import Path

from nsft_pgp_utils.home_dir import create_and_assign_proper_permissions_to_gpg_home_dir
from test_lib.gpg_ctx import mk_gpg_proc_ctx_for
from test_lib.gpg_ctx_checks import (
    check_minimal_gpg_home_dir_empty,
    check_minimal_gpg_home_dir_w_secret_id,
)
from test_lib.gpg_ctx_fixture_gen import (
    generate_gpg_ctx_w_2_distinct_secret_ids_cached,
    generate_gpg_ctx_w_2_same_user_secret_ids_cached,
    generate_gpg_ctx_w_secret_id_cached,
)

LOGGER = logging.getLogger(__name__)


def test_create_and_assign_proper_permissions_to_gpg_home_dir(
        tmp_user_home_dir: Path) -> None:
    LOGGER.info("tmp_user_home_dir: %s", type(tmp_user_home_dir))
    proc_ctx = mk_gpg_proc_ctx_for(tmp_user_home_dir)
    create_and_assign_proper_permissions_to_gpg_home_dir(proc_ctx=proc_ctx)
    check_minimal_gpg_home_dir_empty(proc_ctx)


def test_create_gpg_secret_identity(
        request, tmp_user_home_dir: Path) -> None:
    gpg_ctx = generate_gpg_ctx_w_secret_id_cached(tmp_user_home_dir, request)
    check_minimal_gpg_home_dir_w_secret_id(gpg_ctx.proc)


def test_create_gpg_secret_identity_twice(
        request, tmp_user_home_dir: Path) -> None:
    gpg_ctx = generate_gpg_ctx_w_2_distinct_secret_ids_cached(
        tmp_user_home_dir, request)
    check_minimal_gpg_home_dir_w_secret_id(gpg_ctx.proc)


def test_create_gpg_secret_identity_twice_same_user(
        request, tmp_user_home_dir: Path) -> None:
    gpg_ctx = generate_gpg_ctx_w_2_same_user_secret_ids_cached(
        tmp_user_home_dir, request)
    check_minimal_gpg_home_dir_w_secret_id(gpg_ctx.proc)
