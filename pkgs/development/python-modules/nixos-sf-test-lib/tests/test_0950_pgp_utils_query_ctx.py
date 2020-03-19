
import logging
import subprocess

import pytest

from typing import Set

from nsft_pgp_utils.query import (list_gpg_keys, list_gpg_ownertrust,
                                  list_gpg_secret_keys)
from test_lib.gpg_ctx import GpgContextWInfo

LOGGER = logging.getLogger(__name__)


def _get_gpg_keys_set(gpg_ctx: GpgContextWInfo) -> Set[str]:
    keys = list_gpg_keys(proc_ctx=gpg_ctx.proc)
    return {k.key for k in keys}


def _check_expected_keys(
        gpg_ctx: GpgContextWInfo) -> None:
    keys = list_gpg_keys(proc_ctx=gpg_ctx.proc)
    LOGGER.info(f"keys: {keys}")

    found_emails = {k.email for k in keys}
    LOGGER.info(f"found_emails: {found_emails}")

    expected_emails = {k.email for k in gpg_ctx.info.secret_keys}
    assert len(found_emails) >= len(expected_emails)

    for ski in gpg_ctx.info.secret_keys:
        assert ski.email in found_emails


def _check_expected_secret_keys(
        gpg_ctx: GpgContextWInfo) -> None:
    skeys = list_gpg_secret_keys(gpg_ctx.auth, gpg_ctx.proc)
    LOGGER.info(f"skeys: {skeys}")
    found_emails = {k.email for k in skeys}
    LOGGER.info(f"found_emails: {found_emails}")

    expected_emails = {k.email for k in gpg_ctx.info.secret_keys}
    assert len(found_emails) == len(expected_emails)

    for ski in gpg_ctx.info.secret_keys:
        assert ski.email in found_emails


def _check_expected_keys_and_secret_keys(
        gpg_ctx: GpgContextWInfo) -> None:
    _check_expected_keys(gpg_ctx)
    _check_expected_secret_keys(gpg_ctx)


def test_list_gpg_keys_on_ro_gpg_home(
        gpg_ctx_w_secret_id_ro: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_w_secret_id_ro
    # This is a known gpg bug.
    # See [gnupg - gpg list keys error trustdb is not writable - Stack
    # Overflow](https://stackoverflow.com/questions/41916857/gpg-list-keys-error-trustdb-is-not-writable)

    with pytest.raises(subprocess.CalledProcessError):
        list_gpg_keys(proc_ctx=gpg_ctx.proc)

    with pytest.raises(subprocess.CalledProcessError):
        list_gpg_secret_keys(gpg_ctx.auth, gpg_ctx.proc)


def test_list_gpg_keys_on_empty_minimal_gpg_home(
        gpg_ctx_empty_minimal_dirs: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_empty_minimal_dirs
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_on_no_dirs_gpg_home(
        gpg_ctx_empty_no_dirs: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_empty_no_dirs
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_2_distinct(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_distinct_secret_ids
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_2_same(
        gpg_ctx_w_2_same_user_secret_ids: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_same_user_secret_ids
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_ownertrust_2_distinct(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_distinct_secret_ids
    otrust = list_gpg_ownertrust(proc_ctx=gpg_ctx.proc)
    assert 2 == len(otrust)

    keys = _get_gpg_keys_set(gpg_ctx)

    for e in otrust:
        assert 6 == e.trust_level
        assert e.key in keys
