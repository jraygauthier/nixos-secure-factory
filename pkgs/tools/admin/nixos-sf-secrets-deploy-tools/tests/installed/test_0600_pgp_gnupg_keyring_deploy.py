import logging
import os
import subprocess
from pathlib import Path
from dataclasses import dataclass
from typing import Tuple, Iterable, Callable, Dict, List, Union

import pytest

from nsft_pgp_utils.ctx_types import (
    GpgContext,
    GpgContextWExtInfo,
    mk_empty_gpg_ctx_w_ext_info,
    GpgKeyWExtInfoWOTrust,
    GpgContextKeysWExtInfo,
)
from nsft_pgp_utils.key_types import GpgKeyExtInfoWOTrust, GpgTrust
from nsft_pgp_utils.query import query_gpg_context_w_ext_info
from nsft_shell_utils.outcome import ExpShOutcomeByCtxSoftT
from nsft_system_utils.permissions import (
    FilePermissionsOptsSoftT,
    change_file_permissions,
    ensure_file_permissions_opt,
    ensure_file_permissions_w_ref,
    format_file_permission,
)
from test_lib.checks import check_has_expected_permissions
from test_lib.env import from_nixos_test_machine, get_current_ctx_outcome
from test_lib.gpg_ctx_fixture_gen import (
    WhoI,
    WhoIToCtxMapping,
)

mark_only_for_nixos_test_machine = pytest.mark.skipif(
    not from_nixos_test_machine(),
    reason="Only reproducible on controlled test machine."
)


def _load_fix_ctx(ctx: GpgContext) -> GpgContextWExtInfo:
    if ctx.proc.home_dir.exists():
        return query_gpg_context_w_ext_info(**ctx.as_proc_auth_dict())

    # In this case, we avoid calling any gpg commands those will
    # oftentime create files in the gpg directory which we want
    # to avoid to preserve this *empty dir* state.
    return mk_empty_gpg_ctx_w_ext_info(**ctx.as_proc_auth_dict())


_exe_keys = "nsf-pgp-gnupg-keys-deploy"
_exe_otrust = "nsf-pgp-gnupg-otrust-deploy"

_m = WhoI.m
_f = WhoI.f
_s = WhoI.s
_t = WhoI.t
_z = WhoI.z


_GpgKeysFprDict = Dict[str, GpgKeyExtInfoWOTrust]


def _mk_by_fpr_dict_from_keys(
        in_keys: List[GpgKeyWExtInfoWOTrust]) -> _GpgKeysFprDict:
    return {sk.fpr: sk.info for sk in in_keys}


@dataclass
class _GpgCtxKeysD:
    public: _GpgKeysFprDict
    secret: _GpgKeysFprDict
    all: _GpgKeysFprDict


def _mk_by_fpr_ds_from_ctx_keys(
        in_ctxKeys: GpgContextKeysWExtInfo) -> _GpgCtxKeysD:
    return _GpgCtxKeysD(
        public=_mk_by_fpr_dict_from_keys(in_ctxKeys.public),
        secret=_mk_by_fpr_dict_from_keys(in_ctxKeys.secret),
        all=_mk_by_fpr_dict_from_keys(in_ctxKeys.all),
    )


@dataclass
class _GpgCtxKeys:
    by_ix: GpgContextKeysWExtInfo
    by_fpr: _GpgCtxKeysD


def _mk_ctx_keys(in_ctx: GpgContextWExtInfo) -> _GpgCtxKeys:
    return _GpgCtxKeys(
        by_ix=in_ctx.keys,
        by_fpr=_mk_by_fpr_ds_from_ctx_keys(in_ctx.keys)
    )


@dataclass
class _GpgPerCtxKeys:
    init: _GpgCtxKeys
    before: _GpgCtxKeys
    src: _GpgCtxKeys
    after: _GpgCtxKeys


def _mk_gpg_per_ctx_keys(
        init: GpgContextWExtInfo,
        before: GpgContextWExtInfo,
        src: GpgContextWExtInfo,
        after: GpgContextWExtInfo
) -> _GpgPerCtxKeys:
    return _GpgPerCtxKeys(
        init=_mk_ctx_keys(init),
        before=_mk_ctx_keys(before),
        src=_mk_ctx_keys(src),
        after=_mk_ctx_keys(after)
    )


_CheckContextFnT = Callable[[_GpgPerCtxKeys], None]
_CheckContextExpT = Union[None, _CheckContextFnT, Iterable[_CheckContextFnT]]
_CmdT = Tuple[WhoI, str, WhoI, str, ExpShOutcomeByCtxSoftT, _CheckContextExpT]


def _check_nothing(
        per_ctx_keys: _GpgPerCtxKeys) -> None:
    pass


def ensure_flat_check_fn(
        in_fns: _CheckContextExpT
) -> _CheckContextFnT:
    if in_fns is None:
        return _check_nothing

    if callable(in_fns):
        return in_fns

    def _check_multi(per_ctx_keys: _GpgPerCtxKeys) -> None:
        assert isinstance(in_fns, Iterable)
        for fn in in_fns:
            fn(per_ctx_keys)

    return _check_multi


def _mk_check_public_new_key_import_of_secret_key_at_ix(
        ix: int) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        assert per_ctx_keys.before.by_fpr.public.get(src_key.fpr, None) is None
        assert per_ctx_keys.after.by_fpr.public.get(src_key.fpr, None) is not None

    return _check


def _mk_check_public_key_from_import_of_secret_key_at_ix_exists(
        ix: int) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        assert per_ctx_keys.after.by_fpr.public.get(src_key.fpr, None) is not None

    return _check


def _mk_check_secret_new_key_import_of_secret_key_at_ix(
        ix: int) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        assert per_ctx_keys.before.by_fpr.secret.get(src_key.fpr, None) is None
        assert per_ctx_keys.after.by_fpr.secret.get(src_key.fpr, None) is not None

    return _check


def _mk_check_secret_key_from_import_of_secret_key_at_ix_exists(
        ix: int) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        assert per_ctx_keys.after.by_fpr.secret.get(src_key.fpr, None) is not None

    return _check


def _mk_check_otrust_import_of_secret_key_at_ix(
        ix: int) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        a_key_info = per_ctx_keys.after.by_fpr.all.get(src_key.fpr, None)
        assert a_key_info is not None
        assert a_key_info.otrust == src_key.info.otrust
        assert a_key_info.trust == src_key.info.trust

    return _check


def _mk_check_imported_otrust_secret_key_at_ix_is(
        ix: int,
        expected_otrust: GpgTrust
) -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        src_key = per_ctx_keys.src.by_ix.secret[ix]
        a_key_info = per_ctx_keys.after.by_fpr.all.get(src_key.fpr, None)
        assert a_key_info is not None
        assert a_key_info.otrust == expected_otrust

    return _check


def _mk_check_unchanged_keys() -> _CheckContextFnT:
    def _check(per_ctx_keys: _GpgPerCtxKeys) -> None:
        b_keys = per_ctx_keys.before.by_ix.all
        b_count = len(b_keys)

        a_keys = per_ctx_keys.after.by_ix.all
        a_count = len(a_keys)

        assert b_count == a_count
        assert b_keys == a_keys

    return _check


# TODO:
#
# - Expired keys in gpg context. Could it still decrypt stuff?
#
#
@pytest.mark.parametrize(
    "who_tgt, cmds, inh_permissions", [
        # TODO: Check that we fail as expected when source extension is wrong.

        # Check the whole key distribution pipeline, starting with no gpg context
        # at all (z) to an updated gpg context with the help of a separate decrypter
        # for installing the initial context.
        (_z, [
            # Initial context (s) decrypted by a helper decrypter gpg context (f)
            # into
            (_s, "exported-s/0/enc-for-r-f/subkeys.gpg-keys.asc.b64.gpg",
                _f, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        r'gpg: directory .+\.gnupg\' created',
                        r'gpg: keybox .+.gnupg/pubring\.kbx\' created',
                        r'gpg: .+\.gnupg/trustdb\.gpg: trustdb created',
                        (r'gpg: key [0-9A-F]+: public key '
                            r'[^\<]+\<initial-single-s@secrets.com\>\" imported'),
                        r'gpg: key [0-9A-F]+: secret key imported',
                        r'secret keys imported: 1'
                    ]),
                ), [
                    _mk_check_secret_new_key_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUnknown)
                ]),
            # Import of s's otrust db by z itself (whose identity is that of s).
            (_s, "exported-s/enc-for-r-s/otrust.gpg-otrust.b64.gpg",
                _z, _exe_otrust, (
                    (0, [r'\$ gpg'], [
                        r'gpg: inserting ownertrust of 6',
                    ]),
                ), [
                    _mk_check_secret_key_from_import_of_secret_key_at_ix_exists(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate)
                ]),
            # Update of z's subkeys by and identical set of subkey. It shouldn't
            # change anything.
            (_s, "exported-s/0/enc-for-r-s/subkeys.gpg-keys.asc.b64.gpg",
                _z, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        (r'gpg: key [0-9A-F]+:'
                            r'[^\<]+\<initial-single-s@secrets.com\>\" not changed'),
                        r'gpg: key [0-9A-F]+: secret key imported',
                        r'gpg:[ ]+secret keys unchanged: 1'
                    ]),
                ), [
                    _mk_check_secret_key_from_import_of_secret_key_at_ix_exists(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate)
                ]),
            # Update of z's subkey by a totally different id (f). It shouldn't cause
            # any issue.
            (_f, "exported-f/1/enc-for-r-s/subkeys.gpg-keys.asc.b64.gpg",
                _z, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        (r'gpg: key [0-9A-F]+: public key'
                            r'[^\<]+\<initial-wife-f@secrets.com\>\" imported'),
                        r'gpg: key [0-9A-F]+: secret key imported',
                        r'gpg:[ ]+secret keys imported: 1'
                    ]),
                ), [
                    _mk_check_secret_new_key_import_of_secret_key_at_ix(1),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        1, GpgTrust.TrustUnknown)
                ]),
            # Now that z is f (the wife) too, it shouldn't have any trouble
            # decrypting stuff enrypted for f (the man's public id).
            # Note how we exercise the non b64 encoded version too.
            (_f, "exported-f/0/enc-for-r-f/public.gpg-keys.asc.gpg",
                _z, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        (r'gpg: key [0-9A-F]+: public key'
                            r'[^\<]+\<initial-man-f@secrets.com\>\" imported'),
                        r'gpg:[ ]+imported: 1'
                    ]),
                ), [
                    _mk_check_public_new_key_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUnknown)
                ]),
            # But z is still s, and as such it should have lost the ability to
            # decrypt stuff intended for s. We will take the otrust for our
            # now reunited family as an exemple.
            # Note how we exercise the non b64 encoded version too.
            (_f, "exported-f/enc-for-r-s/otrust.gpg-otrust.gpg",
                _z, _exe_otrust, (
                    (0, [r'\$ gpg'], [
                        r'gpg: inserting ownertrust of 6'
                    ]),
                ), [
                    _mk_check_public_key_from_import_of_secret_key_at_ix_exists(0),
                    _mk_check_secret_key_from_import_of_secret_key_at_ix_exists(1),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        1, GpgTrust.TrustUltimate)
                ]),
        ], None),
        # Check that importing public, otrust and then secret behave as expected.
        (_s, [
            (_f, "exported-f/0/enc-for-r-s/public.gpg-keys.asc.b64.gpg",
                _s, _exe_keys, (
                    (0, [r'\$ gpg'], [r'\<initial-man-f\@secrets.com\>" imported']),
                ), _mk_check_public_new_key_import_of_secret_key_at_ix(0)),
            (_f, "exported-f/enc-for-r-s/otrust.gpg-otrust.b64.gpg",
                _s, _exe_otrust, (
                    (0, [r'\$ gpg'], [
                        r'gpg: inserting ownertrust of 6'
                    ]),
                ), [
                    _mk_check_otrust_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate)
                ]),
            (_f, "exported-f/0/enc-for-r-s/secret.gpg-keys.asc.b64.gpg",
                _s, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        r'gpg: ',
                        r'gpg:[^\<]+\<initial-man-f\@secrets.com\>" not changed',
                        r'secret key imported'
                    ]),
                ), [
                    _mk_check_secret_new_key_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate)
                ]),
        ], None),
        # Check that when importing otrust before importing matching keys, the
        # otrust lines targeting those keys are skipped. However, those can
        # be imported later.
        # Also checks that this is fine to import public keys after secret keys.
        (_s, [
            (_f, "exported-f/enc-for-r-s/otrust.gpg-otrust.b64.gpg",
                _s, _exe_otrust, (
                    (0, [r'\$ gpg'], [
                        r'Cannot deploy otrust line'
                    ]),
                ), _mk_check_unchanged_keys()),
            (_f, "exported-f/0/enc-for-r-s/secret.gpg-keys.asc.b64.gpg",
                _s, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        r'gpg:[^\<]+\<initial-man-f\@secrets.com\>" imported'
                    ]),
                ), [
                    _mk_check_secret_new_key_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUnknown)
                ]),
            (_f, "exported-f/0/enc-for-r-s/public.gpg-keys.asc.b64.gpg",
                _s, _exe_keys, (
                    (0, [r'\$ gpg'], [
                        r'gpg:[^\<]+\<initial-man-f\@secrets.com\>" not changed',
                        r'gpg:[ ]+unchanged:[ ]+1'
                    ]),
                ), [
                    _mk_check_secret_key_from_import_of_secret_key_at_ix_exists(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUnknown)
                ]),
            (_f, "exported-f/enc-for-r-s/otrust.gpg-otrust.b64.gpg",
                _s, _exe_otrust, (
                    (0, [r'\$ gpg'], [
                        r'gpg: inserting ownertrust of 6'
                    ]),
                ), [
                    _mk_check_otrust_import_of_secret_key_at_ix(0),
                    _mk_check_imported_otrust_secret_key_at_ix_is(
                        0, GpgTrust.TrustUltimate)
                ]),
        ], None),
    ])
def test_pgp_gnupg_keyring_deploy(
        src_gnupg_keyring_deploy_dir: Path,
        tgt_gnupg_keyring_deploy_who_to_ctx_map: WhoIToCtxMapping,
        who_tgt: WhoI,
        cmds: Iterable[_CmdT],
        inh_permissions: FilePermissionsOptsSoftT) -> None:

    src_fix_dir = src_gnupg_keyring_deploy_dir
    fix_tgt_ctx = tgt_gnupg_keyring_deploy_who_to_ctx_map(who_tgt)
    inh_permissions = ensure_file_permissions_opt(inh_permissions)

    tgt_gnupg_home_dir = fix_tgt_ctx.proc.home_dir
    tgt_init_ghd_ctx = _load_fix_ctx(fix_tgt_ctx)

    for c in cmds:
        (who_src, rel_src_file, who_decrypt,
            exe_name, exp_outcome_by_ctx, check_ctx_fn) = c
        check_ctx_fn = ensure_flat_check_fn(check_ctx_fn)

        logging.info(f"tgt gpg home_dir: {fix_tgt_ctx.proc.home_dir}")
        src_ctx = tgt_gnupg_keyring_deploy_who_to_ctx_map(who_src)
        logging.info(f"src gpg homedir: {src_ctx.proc.home_dir}")
        fix_decrypt_ctx = tgt_gnupg_keyring_deploy_who_to_ctx_map(who_decrypt)
        logging.info(f"decrypter gpg homedir: {fix_decrypt_ctx.proc.home_dir}")

        exp_outcome = get_current_ctx_outcome(exp_outcome_by_ctx)

        src_file = src_fix_dir.joinpath(rel_src_file)

        tgt_before_ghd_homedir_present = tgt_gnupg_home_dir.exists()
        tgt_before_ghd_ctx = _load_fix_ctx(fix_tgt_ctx)

        logging.info("src_file: %s", src_file)

        change_file_permissions(tgt_gnupg_home_dir, inh_permissions)

        logging.info(
            "tgt_tmp_dir permissions: {%s}",
            format_file_permission(tgt_gnupg_home_dir))

        exp_permissions = None
        if tgt_gnupg_home_dir.exists():
            exp_permissions = ensure_file_permissions_w_ref(
                inh_permissions, tgt_gnupg_home_dir)

        # TODO: Test tgt home dir via:
        # - Env var
        #    -> Impacts decryption. Not specifying pos arg is an error.
        # - Positional argument
        #    -> Impacts only import
        # - Option --gpg-homedir
        #    -> Impacts both decryption and import
        # - Both option and positional argument
        #    -> The option impacts decryption wereas the position argument
        #       impacts import.

        def call_program():
            dec_gpghomedir = fix_decrypt_ctx.proc.home_dir
            env = {}
            env.update(os.environ)
            env.update({
                'GNUPGHOME': f"{dec_gpghomedir}"
            })
            logging.info(
                f"GNUPGHOME={dec_gpghomedir} {exe_name} "
                f"'{src_file}' '{tgt_gnupg_home_dir}'")
            return subprocess.run(
                [
                    exe_name,
                    src_file,
                    tgt_gnupg_home_dir
                ],
                check=True, text=True,
                stdout=(None if exp_outcome.stdout.no_expects() else subprocess.PIPE),
                stderr=(None if exp_outcome.stderr.no_expects() else subprocess.PIPE),
                env=env
            )

        if not exp_outcome.success():
            with pytest.raises(subprocess.CalledProcessError) as e:
                call_program()

            exp_outcome.check_expected_error(e.value)

            if not tgt_before_ghd_homedir_present:
                # When there was no original file, there should still be no file on
                # error.
                assert not os.path.exists(tgt_gnupg_home_dir)
            else:
                # When an original file was present, it should still be there and
                # its content unchanged.
                assert os.path.exists(tgt_gnupg_home_dir)

            tgt_post_error_ghd_ctx = _load_fix_ctx(fix_tgt_ctx)
            assert tgt_before_ghd_ctx == tgt_post_error_ghd_ctx

            check_ctx_fn(_mk_gpg_per_ctx_keys(
                tgt_init_ghd_ctx, tgt_before_ghd_ctx, src_ctx, tgt_post_error_ghd_ctx))

            return

        comleted_proc = call_program()
        exp_outcome.check_expected_success(comleted_proc)

        assert os.path.exists(tgt_gnupg_home_dir)

        logging.info(
            "tgt_gnupg_home_dir permissions: {%s}",
            format_file_permission(tgt_gnupg_home_dir))

        if exp_permissions is not None:
            check_has_expected_permissions(tgt_gnupg_home_dir, exp_permissions)

        tgt_new_ghd_ctx = _load_fix_ctx(fix_tgt_ctx)
        check_ctx_fn(_mk_gpg_per_ctx_keys(
            tgt_init_ghd_ctx, tgt_before_ghd_ctx, src_ctx, tgt_new_ghd_ctx))
