import pytest
import logging
from typing import Iterable

from nsft_pgp_utils.ctx_gen_types import GpgContextWGenInfo
from nsft_pgp_utils.ctx_types import GpgContextWExtInfo
from nsft_pgp_utils.io_export import export_gpg_public_key_to_text
from nsft_pgp_utils.io_import import import_gpg_key_text, import_gpg_ui_otrust
from nsft_pgp_utils.key_types import GpgKeyWUIOwnerTrust, GpgKeyWExtInfoWOTrust
from nsft_pgp_utils.query import (query_gpg_context_keys_w_ext_info,
                                  query_gpg_context_w_ext_info)
from nsft_pgp_utils.trust import sign_gpg_key, trust_gpg_key, sign_and_trust_gpg_key
from nsft_pgp_utils.trust_types import GpgTrust, GpgOwnerTrust


def _check_unsigned_freshly_imported_keys(
        imp_keys: Iterable[GpgKeyWExtInfoWOTrust]) -> None:
    for ik in imp_keys:
        assert GpgTrust.TrustUnknown == ik.info.trust
        assert GpgTrust.TrustUnknown == ik.info.otrust


@pytest.fixture
def gpg_ctx_w_secret_id_and_2_freshly_imported_keys(
    gpg_ctx_w_2_distinct_secret_ids: GpgContextWGenInfo,
    gpg_ctx_w_secret_id: GpgContextWGenInfo
) -> GpgContextWExtInfo:
    exp_ctx = gpg_ctx_w_2_distinct_secret_ids
    imp_ctx = gpg_ctx_w_secret_id

    assert 2 == len(exp_ctx.gen_info.secret_keys)

    for sk in exp_ctx.gen_info.secret_keys:
        exp_text = export_gpg_public_key_to_text(
            sk.email,
            auth=exp_ctx.auth, proc=exp_ctx.proc)

        import_gpg_key_text(exp_text, **imp_ctx.as_proc_dict())

    out_ctx = query_gpg_context_w_ext_info(**imp_ctx.as_proc_auth_dict())
    imp_keys = out_ctx.keys.public
    assert 2 == len(imp_keys)

    _check_unsigned_freshly_imported_keys(imp_keys)

    return out_ctx


def test_import_gpg_ui_otrust_and_then_sign_gpg_key(
        gpg_ctx_w_secret_id_and_2_freshly_imported_keys: GpgContextWExtInfo
) -> None:
    ctx = gpg_ctx_w_secret_id_and_2_freshly_imported_keys
    logging.info(f"ctx.proc.home_dir: {ctx.proc.home_dir}")

    imp_keys = ctx.keys.public

    ui_otrust = [
        GpgKeyWUIOwnerTrust(imp_keys[0].fpr, GpgOwnerTrust.Fully),
        GpgKeyWUIOwnerTrust(imp_keys[1].fpr, GpgOwnerTrust.Marginal)
    ]

    import_gpg_ui_otrust(ui_otrust, **ctx.as_proc_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    # Here, we see that as long as key are not signed, their
    # *computed trust* will show "unknown". That is, unless
    # the key is ultimately trusted which shouldn't be used
    # on other keys.
    assert GpgTrust.TrustUnknown == imp_keys[0].info.trust
    assert GpgTrust.TrustUnknown == imp_keys[1].info.trust

    assert GpgTrust.TrustFully == imp_keys[0].info.otrust
    assert GpgTrust.TrustMarginal == imp_keys[1].info.otrust

    #
    # After signing, the "computed trust" becomes "fully"
    # contrary to what we might expect (marginal for the second entry).
    #
    for ik in imp_keys:
        sign_gpg_key(ik.fpr, **ctx.as_proc_auth_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    assert GpgTrust.TrustFully == imp_keys[0].info.trust
    assert GpgTrust.TrustFully == imp_keys[1].info.trust

    assert GpgTrust.TrustFully == imp_keys[0].info.otrust
    assert GpgTrust.TrustMarginal == imp_keys[1].info.otrust

    ui_otrust = [
        GpgKeyWUIOwnerTrust(imp_keys[0].fpr, GpgOwnerTrust.Never),
        GpgKeyWUIOwnerTrust(imp_keys[1].fpr, GpgOwnerTrust.Never)
    ]

    #
    # Even tough we attempt import again distrusting the keys, the "computed
    # trust" remains unchanged (i.e: "fully").
    #
    import_gpg_ui_otrust(ui_otrust, **ctx.as_proc_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    assert GpgTrust.TrustFully == imp_keys[0].info.trust
    assert GpgTrust.TrustFully == imp_keys[1].info.trust

    assert GpgTrust.TrustNever == imp_keys[0].info.otrust
    assert GpgTrust.TrustNever == imp_keys[1].info.otrust


def test_sign_gpg_key(
        gpg_ctx_w_secret_id_and_2_freshly_imported_keys: GpgContextWExtInfo
) -> None:
    ctx = gpg_ctx_w_secret_id_and_2_freshly_imported_keys
    logging.info(f"ctx.proc.home_dir: {ctx.proc.home_dir}")

    imp_keys = ctx.keys.public

    #
    # We see here that signing a key mean to effectively trust it fully (i.e:
    # computed trust).
    #
    for ik in imp_keys:
        sign_gpg_key(ik.fpr, **ctx.as_proc_auth_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    for ik in imp_keys:
        assert GpgTrust.TrustFully == ik.info.trust
        # However, the owner trust remains unknown.
        assert GpgTrust.TrustUnknown == ik.info.otrust


def test_trust_gpg_key(
        gpg_ctx_w_secret_id_and_2_freshly_imported_keys: GpgContextWExtInfo
) -> None:
    ctx = gpg_ctx_w_secret_id_and_2_freshly_imported_keys
    logging.info(f"ctx.proc.home_dir: {ctx.proc.home_dir}")

    imp_keys = ctx.keys.public

    ui_otrust = [
        GpgOwnerTrust.Fully,
        GpgOwnerTrust.Marginal
    ]

    for ik, uiot in zip(imp_keys, ui_otrust):
        trust_gpg_key(ik.fpr, uiot, **ctx.as_proc_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    # Same think applies as observed in
    # `test_import_gpg_ui_otrust_and_then_sign_gpg_key`.
    for ik in imp_keys:
        assert GpgTrust.TrustUnknown == ik.info.trust

    assert GpgTrust.TrustFully == imp_keys[0].info.otrust
    assert GpgTrust.TrustMarginal == imp_keys[1].info.otrust


def test_sign_and_trust_gpg_key(
        gpg_ctx_w_secret_id_and_2_freshly_imported_keys: GpgContextWExtInfo
) -> None:
    ctx = gpg_ctx_w_secret_id_and_2_freshly_imported_keys
    logging.info(f"ctx.proc.home_dir: {ctx.proc.home_dir}")

    imp_keys = ctx.keys.public

    ui_otrust = [
        GpgOwnerTrust.Fully,
        GpgOwnerTrust.Marginal
    ]

    for ik, uiot in zip(imp_keys, ui_otrust):
        sign_and_trust_gpg_key(ik.fpr, uiot, **ctx.as_proc_dict())

    imp_keys = query_gpg_context_keys_w_ext_info(**ctx.as_proc_auth_dict()).public
    assert 2 == len(imp_keys)

    # Same think applies as observed in
    # `test_import_gpg_ui_otrust_and_then_sign_gpg_key`.
    for ik in imp_keys:
        assert GpgTrust.TrustFully == ik.info.trust

    assert GpgTrust.TrustFully == imp_keys[0].info.otrust
    assert GpgTrust.TrustMarginal == imp_keys[1].info.otrust
