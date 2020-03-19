import logging
from pathlib import Path

from nsft_pgp_utils.io_export import (export_gpg_otrust_to_file,
                                      export_gpg_public_key_to_file,
                                      export_gpg_secret_keys_to_file,
                                      export_gpg_secret_subkeys_to_file)
from nsft_pgp_utils.io_import import (import_gpg_key_file,
                                      import_gpg_otrust_file)
from nsft_pgp_utils.io_query import (list_gpg_keys_from_file,
                                     list_gpg_ownertrust_from_file)
from nsft_pgp_utils.query import (list_gpg_keys, list_gpg_ownertrust,
                                  list_gpg_secret_keys)
from test_lib.gpg_ctx import GpgContextWInfo

LOGGER = logging.getLogger(__name__)


def test_export_and_import_secret_id(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo,
        tmp_export_dir: Path,
        gpg_ctx_empty_minimal_dirs: GpgContextWInfo) -> None:

    exp_ctx = gpg_ctx_w_2_distinct_secret_ids
    imp_ctx = gpg_ctx_empty_minimal_dirs

    assert 2 == len(exp_ctx.info.secret_keys)
    exp_email = exp_ctx.info.secret_keys[1].email

    secret_keys_path = tmp_export_dir.joinpath("secret.gpg-keys")
    export_gpg_secret_keys_to_file(
        secret_keys_path, exp_ctx.info.secret_keys[1].email,
        auth_ctx=exp_ctx.auth, proc_ctx=exp_ctx.proc)

    list_keys = list_gpg_keys_from_file(secret_keys_path, proc_ctx=imp_ctx.proc)
    assert 1 == len(list_keys)
    assert exp_email == list_keys[0].email

    import_gpg_key_file(secret_keys_path, proc_ctx=imp_ctx.proc)

    imp_keys = list_gpg_keys(proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_keys)
    assert exp_email == imp_keys[0].email

    imp_skeys = list_gpg_secret_keys(auth_ctx=imp_ctx.auth, proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_skeys)
    assert exp_email == imp_skeys[0].email


def test_export_and_import_public_id(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo,
        tmp_export_dir: Path,
        gpg_ctx_empty_minimal_dirs: GpgContextWInfo) -> None:

    exp_ctx = gpg_ctx_w_2_distinct_secret_ids
    imp_ctx = gpg_ctx_empty_minimal_dirs

    assert 2 == len(exp_ctx.info.secret_keys)
    exp_email = exp_ctx.info.secret_keys[1].email

    public_keys_path = tmp_export_dir.joinpath("public.gpg-keys")
    export_gpg_public_key_to_file(
        public_keys_path, exp_ctx.info.secret_keys[1].email,
        auth_ctx=exp_ctx.auth, proc_ctx=exp_ctx.proc)

    import_gpg_key_file(public_keys_path, proc_ctx=imp_ctx.proc)

    imp_skeys = list_gpg_secret_keys(auth_ctx=imp_ctx.auth, proc_ctx=imp_ctx.proc)
    assert 0 == len(imp_skeys)

    imp_keys = list_gpg_keys(proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_keys)
    assert exp_email == imp_keys[0].email


def test_export_and_import_secret_subkeys(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo,
        tmp_export_dir: Path,
        gpg_ctx_empty_minimal_dirs: GpgContextWInfo) -> None:

    exp_ctx = gpg_ctx_w_2_distinct_secret_ids
    imp_ctx = gpg_ctx_empty_minimal_dirs

    assert 2 == len(exp_ctx.info.secret_keys)
    exp_email = exp_ctx.info.secret_keys[1].email

    subkeys_path = tmp_export_dir.joinpath("subkeys.gpg-keys")
    export_gpg_secret_subkeys_to_file(
        subkeys_path, exp_ctx.info.secret_keys[1].email,
        auth_ctx=exp_ctx.auth, proc_ctx=exp_ctx.proc)

    list_keys = list_gpg_keys_from_file(subkeys_path, proc_ctx=imp_ctx.proc)
    assert 1 == len(list_keys)
    assert exp_email == list_keys[0].email

    import_gpg_key_file(subkeys_path, proc_ctx=imp_ctx.proc)

    imp_keys = list_gpg_keys(proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_keys)
    assert exp_email == imp_keys[0].email

    imp_skeys = list_gpg_secret_keys(auth_ctx=imp_ctx.auth, proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_skeys)
    assert exp_email == imp_skeys[0].email


def test_export_and_import_otrust(
        gpg_ctx_w_2_distinct_secret_ids: GpgContextWInfo,
        tmp_export_dir: Path,
        gpg_ctx_empty_minimal_dirs: GpgContextWInfo) -> None:

    exp_ctx = gpg_ctx_w_2_distinct_secret_ids
    imp_ctx = gpg_ctx_empty_minimal_dirs

    exp_otrust = list_gpg_ownertrust(proc_ctx=exp_ctx.proc)
    assert 2 == len(exp_otrust)

    assert 2 == len(exp_ctx.info.secret_keys)

    subkeys_path = tmp_export_dir.joinpath("subkeys.gpg-keys")
    LOGGER.info(f"export_gpg_secret_subkeys_to_file(\"{subkeys_path}\", ..)")
    export_gpg_secret_subkeys_to_file(
        subkeys_path, exp_ctx.info.secret_keys[1].email,
        auth_ctx=exp_ctx.auth, proc_ctx=exp_ctx.proc)

    otrust_path = tmp_export_dir.joinpath("exported.gpg-otrust")
    LOGGER.info(f"export_gpg_otrust_to_file(\"{otrust_path}\", ..)")
    export_gpg_otrust_to_file(
        otrust_path,
        auth_ctx=exp_ctx.auth, proc_ctx=exp_ctx.proc)

    file_otrust = list_gpg_ownertrust_from_file(otrust_path)
    assert 2 == len(file_otrust)
    assert exp_otrust == file_otrust

    import_gpg_key_file(subkeys_path, proc_ctx=imp_ctx.proc)
    import_gpg_otrust_file(otrust_path, proc_ctx=imp_ctx.proc)

    imp_skeys = list_gpg_secret_keys(auth_ctx=imp_ctx.auth, proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_skeys)

    imp_keys = list_gpg_keys(proc_ctx=imp_ctx.proc)
    assert 1 == len(imp_keys)

    imp_otrust = list_gpg_ownertrust(proc_ctx=imp_ctx.proc)
    assert 2 == len(imp_otrust)
    assert file_otrust == imp_otrust
