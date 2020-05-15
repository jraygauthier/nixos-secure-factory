
import logging
from typing import Set

import pytest

from nsft_pgp_utils.ctx_gen_types import GpgContextWGenInfo
from nsft_pgp_utils.query import (query_gpg_context_keys_w_ext_info,
                                  list_gpg_keys, list_gpg_ownertrust,
                                  list_gpg_secret_keys)
from nsft_pgp_utils.trust_types import GpgTrust
from nsft_pgp_utils.errors import GpgProcessError

LOGGER = logging.getLogger(__name__)


def _get_gpg_keys_set(gpg_ctx: GpgContextWGenInfo) -> Set[str]:
    keys = list_gpg_keys(proc=gpg_ctx.proc)
    return {k.fpr for k in keys}


def _get_gpg_email_set(gpg_ctx: GpgContextWGenInfo) -> Set[str]:
    keys = list_gpg_keys(proc=gpg_ctx.proc)
    return {k.email for k in keys}


def _check_expected_keys(
        gpg_ctx: GpgContextWGenInfo) -> None:
    keys = list_gpg_keys(proc=gpg_ctx.proc)
    LOGGER.info(f"keys: {keys}")

    found_emails = {k.email for k in keys}
    LOGGER.info(f"found_emails: {found_emails}")

    expected_emails = {k.email for k in gpg_ctx.gen_info.secret_keys}
    assert len(found_emails) >= len(expected_emails)

    for ski in gpg_ctx.gen_info.secret_keys:
        assert ski.email in found_emails


def _check_expected_secret_keys(
        gpg_ctx: GpgContextWGenInfo) -> None:
    skeys = list_gpg_secret_keys(gpg_ctx.auth, gpg_ctx.proc)
    LOGGER.info(f"skeys: {skeys}")
    found_emails = {k.email for k in skeys}
    LOGGER.info(f"found_emails: {found_emails}")

    expected_emails = {k.email for k in gpg_ctx.gen_info.secret_keys}
    assert len(found_emails) == len(expected_emails)

    for ski in gpg_ctx.gen_info.secret_keys:
        assert ski.email in found_emails


def _check_expected_keys_and_secret_keys(
        gpg_ctx: GpgContextWGenInfo) -> None:
    _check_expected_keys(gpg_ctx)
    _check_expected_secret_keys(gpg_ctx)


@pytest.mark.xfail(
    reason="Flaky expected failure.", raises=GpgProcessError, strict=False)
def test_list_gpg_keys_on_ro_gpg_home(
        gpg_ctx_w_secret_id_ro: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_secret_id_ro
    # This is a known gpg bug.
    # See [gnupg - gpg list keys error trustdb is not writable - Stack
    # Overflow](https://stackoverflow.com/questions/41916857/gpg-list-keys-error-trustdb-is-not-writable)
    list_gpg_keys(proc=gpg_ctx.proc)


@pytest.mark.xfail(
    reason="Flaky expected failure.", raises=GpgProcessError, strict=False)
def test_list_gpg_secret_keys_on_ro_gpg_home(
        gpg_ctx_w_secret_id_ro: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_secret_id_ro
    # This is a known gpg bug.
    # See [gnupg - gpg list keys error trustdb is not writable - Stack
    # Overflow](https://stackoverflow.com/questions/41916857/gpg-list-keys-error-trustdb-is-not-writable)
    list_gpg_secret_keys(auth=gpg_ctx.auth, proc=gpg_ctx.proc)


def test_list_gpg_keys_on_empty_minimal_gpg_home(
        gpg_ctx_empty_minimal_dirs: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_empty_minimal_dirs
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_on_no_dirs_gpg_home(
        gpg_ctx_empty_no_dirs: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_empty_no_dirs
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_2_distinct(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_distinct_secret_ids
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_keys_2_same(
        gpg_ctx_w_2_same_user_secret_ids: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_same_user_secret_ids
    _check_expected_keys_and_secret_keys(gpg_ctx)


def test_list_gpg_ownertrust_2_distinct(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_distinct_secret_ids
    otrust = list_gpg_ownertrust(proc=gpg_ctx.proc)
    assert 2 == len(otrust)

    keys = _get_gpg_keys_set(gpg_ctx)

    for e in otrust:
        assert GpgTrust.TrustUltimate == e.trust
        assert e.fpr in keys


def test_query_gpg_context_keys_w_ext_info(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWGenInfo) -> None:
    gpg_ctx = gpg_ctx_w_2_distinct_secret_ids
    ctx_keys = query_gpg_context_keys_w_ext_info(
        auth=gpg_ctx.auth,
        proc=gpg_ctx.proc)

    assert not ctx_keys.public
    assert 2 == len(ctx_keys.secret)

    keys = _get_gpg_keys_set(gpg_ctx)
    emails = _get_gpg_email_set(gpg_ctx)

    for sk in ctx_keys.secret:
        assert GpgTrust.TrustUltimate == sk.info.trust
        assert sk.fpr in keys
        assert sk.info.email in emails
