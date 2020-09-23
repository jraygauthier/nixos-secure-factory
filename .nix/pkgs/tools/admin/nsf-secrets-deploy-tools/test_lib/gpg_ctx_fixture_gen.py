import os
import shutil
from enum import Enum, auto
from pathlib import Path
from typing import Callable, Iterable, Optional, Tuple, TypeVar

from nsft_cache_utils.dir import (
    OptPyTestFixtureRequestT,
    create_dir_content_cached_from_pytest,
)
from nsft_system_utils.file import write_text_file_content
from nsft_pgp_utils.ctx_auth_types import GpgAuthContext
from nsft_pgp_utils.ctx_gen_types import GpgContextGenInfo, GpgContextWGenInfo
from nsft_pgp_utils.ctx_proc_types import mk_gpg_proc_ctx_for_user_home_dir
from nsft_pgp_utils.encrypt import encrypt_file_to_gpg_file
from nsft_pgp_utils.fixture_encrypt_decrypt import (
    GpgContextWExtInfo,
    GpgEncryptDecryptBasicFixture,
    generate_gpg_encrypt_decrypt_basic_fixture,
    load_gpg_encrypt_decrypt_basic_fixture,
)
from nsft_pgp_utils.fixture_initial import (
    GpgInitialFixture,
    generate_gpg_initial_fixture,
    load_gpg_initial_fixture,
)
from nsft_pgp_utils.home_dir import (
    create_and_assign_proper_permissions_to_gpg_home_dir,
    create_and_assign_proper_permissions_to_user_home_dir,
)
from nsft_pgp_utils.io_export import (
    export_gpg_otrust_to_file,
    export_gpg_public_key_to_file,
    export_gpg_secret_keys_to_file,
    export_gpg_secret_subkeys_to_file
)
from nsft_pgp_utils.key_types import GpgKeyWExtInfoWOTrust

# We had the following trouble with those files during sandboxed copy of the gpg home
# directory:
# ```
# shutil.Error: .. "[Errno 6] No such device or address: '/path/to/.gnupg/S.gpg-agent
# ```
#
# This is why we need to ignore these files.
ignore_copy_for_gpg_home_dir = shutil.ignore_patterns(
    "S.gpg-agent", "S.gpg-agent.*", "S.scdaemon")

_LoadDirContentRetT = TypeVar('_LoadDirContentRetT')


def _create_dir_content_cached(
        dir: Path,
        generate_dir_content_fn: Callable[[Path], _LoadDirContentRetT],
        request: OptPyTestFixtureRequestT,
        load_dir_content_fn: Optional[Callable[[Path], _LoadDirContentRetT]] = None,
) -> _LoadDirContentRetT:
    stale_after_s = None
    return create_dir_content_cached_from_pytest(
        Path(__file__),
        dir,
        generate_dir_content_fn,
        request=request,
        stale_after_s=stale_after_s,
        copy_ignore_fn=ignore_copy_for_gpg_home_dir,
        load_dir_content_fn=load_dir_content_fn
    )


def generate_gpg_ctx_empty_no_dirs(home_dir: Path) -> GpgContextWGenInfo:
    create_and_assign_proper_permissions_to_user_home_dir(home_dir)

    return GpgContextWGenInfo(
        proc=mk_gpg_proc_ctx_for_user_home_dir(home_dir),
        auth=GpgAuthContext(passphrase=""),
        gen_info=GpgContextGenInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_no_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    return generate_gpg_ctx_empty_no_dirs(home_dir)


def generate_gpg_ctx_empty_minimal_dirs(home_dir: Path) -> GpgContextWGenInfo:
    proc = mk_gpg_proc_ctx_for_user_home_dir(home_dir)
    create_and_assign_proper_permissions_to_gpg_home_dir(proc=proc)
    return GpgContextWGenInfo(
        proc=proc,
        auth=GpgAuthContext(passphrase=""),
        gen_info=GpgContextGenInfo(secret_keys=[])
    )


def generate_gpg_ctx_empty_minimal_dirs_cached(
        home_dir: Path, request: OptPyTestFixtureRequestT = None) -> GpgContextWGenInfo:
    return generate_gpg_ctx_empty_minimal_dirs(home_dir)


def generate_gpg_encrypt_decrypt_basic_fixture_cached(
        homes_root_dir: Path, request: OptPyTestFixtureRequestT = None
) -> GpgEncryptDecryptBasicFixture:
    return _create_dir_content_cached(
        homes_root_dir,
        generate_gpg_encrypt_decrypt_basic_fixture,
        request, load_gpg_encrypt_decrypt_basic_fixture)


class WhoED(Enum):
    a = auto()
    b = auto()
    e = auto()


def get_ed_fix_ctx_for(
        fix: GpgEncryptDecryptBasicFixture, who: WhoED) -> GpgContextWExtInfo:
    assert who in WhoED
    return getattr(fix, f"d_{who.name}")


def generate_gpg_initial_fixture_cached(
        homes_root_dir: Path, request: OptPyTestFixtureRequestT = None
) -> GpgInitialFixture:
    return _create_dir_content_cached(
        homes_root_dir,
        generate_gpg_initial_fixture,
        request, load_gpg_initial_fixture)


class WhoI(Enum):
    ie = auto()
    m = auto()
    f = auto()
    s = auto()
    t = auto()
    z = auto()


def get_i_fix_ctx_for(
        fix: GpgInitialFixture, who: WhoI) -> GpgContextWExtInfo:
    assert who in WhoI
    return getattr(fix, f"i_{who.name}")


WhoIToCtxMapping = Callable[[WhoI], GpgContextWExtInfo]


def _encrypt_to_plain_and_b64_ro_gpg(
        out_dir: Path,
        in_file: Path,
        recipients: Iterable[GpgKeyWExtInfoWOTrust],
        enc_ctx: GpgContextWExtInfo) -> Tuple[Path, Path]:
    basename = in_file.name
    out_gpg = encrypt_file_to_gpg_file(
        in_file,
        out_dir.joinpath(f"{basename}.gpg"),
        pre_encode_to_b64=False,
        recipients=map(lambda x: x.fpr, recipients),
        **enc_ctx.as_proc_dict()
    )

    out_gpg_b64 = encrypt_file_to_gpg_file(
        in_file,
        out_dir.joinpath(f"{basename}.b64.gpg"),
        pre_encode_to_b64=True,
        recipients=map(lambda x: x.fpr, recipients),
        **enc_ctx.as_proc_dict()
    )

    # Make these files and dirs ro to flag manip errors.
    os.chmod(out_gpg, mode=0o444)
    os.chmod(out_gpg_b64, mode=0o444)

    return out_gpg, out_gpg_b64


def generate_gpg_encrypted_files_basic(
        out_dir: Path,
        gpg_enc_dec_fix: GpgEncryptDecryptBasicFixture
) -> Path:
    fix = gpg_enc_dec_fix
    tmp_dir = out_dir

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

        enc_gpg_file, enc_gpg_b64_file = \
            _encrypt_to_plain_and_b64_ro_gpg(
                encrypted_dir, original_file, c_rs, fix.e_e)

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


def generate_gpg_initial_fixture_encrypted_exports(
        out_path: Path,
        gpg_initial_fix: GpgInitialFixture
) -> Path:
    i_fix = gpg_initial_fix
    tmp_dir = out_path

    # TODO: It would be nice to have an expired key.
    exp_cases = [
        ("ie", i_fix.i_ie),
        ("f", i_fix.i_f),
        ("s", i_fix.i_s),
        ("t", i_fix.i_t),
    ]

    enc_cases = [
        ("r-all", i_fix.i_ie.keys.all),
        ("r-ie", i_fix.i_ie.keys.secret),
        ("r-f", i_fix.i_f.keys.secret),
        ("r-f1", [i_fix.i_f.keys.secret[0]]),
        ("r-f2", [i_fix.i_f.keys.secret[1]]),
        ("r-s", i_fix.i_s.keys.secret),
        ("r-t", i_fix.i_t.keys.secret),
        ("r-t1", [i_fix.i_t.keys.secret[0]]),
        ("r-t2", [i_fix.i_t.keys.secret[1]]),
    ]

    def _encrypt_file_for_all_enc_cases(out_dir: Path, file: Path) -> None:
        for c_id, c_rs in enc_cases:
            enc_dir = out_dir.joinpath(f"enc-for-{c_id}")
            enc_dir.mkdir(exist_ok=True)
            enc_gpg_file, enc_gpg_b64_file = \
                _encrypt_to_plain_and_b64_ro_gpg(
                    enc_dir, file, c_rs, i_fix.i_ie)

    for c_id, c_ctx in exp_cases:
        exp_dir = tmp_dir.joinpath(f"exported-{c_id}")
        os.mkdir(exp_dir)

        for ski, sk in enumerate(c_ctx.keys.secret):
            exp_k_dir = exp_dir.joinpath(f"{ski}")
            os.mkdir(exp_k_dir)

            skf = export_gpg_secret_keys_to_file(
                exp_k_dir.joinpath("secret.gpg-keys.asc"),
                sk.fpr,
                **c_ctx.as_proc_auth_dict())

            pkf = export_gpg_public_key_to_file(
                exp_k_dir.joinpath("public.gpg-keys.asc"),
                sk.fpr,
                **c_ctx.as_proc_auth_dict())

            subksf = export_gpg_secret_subkeys_to_file(
                exp_k_dir.joinpath("subkeys.gpg-keys.asc"),
                sk.fpr,
                **c_ctx.as_proc_auth_dict())

            _encrypt_file_for_all_enc_cases(exp_k_dir, skf)
            _encrypt_file_for_all_enc_cases(exp_k_dir, pkf)
            _encrypt_file_for_all_enc_cases(exp_k_dir, subksf)

            os.chmod(exp_k_dir, mode=0o555)

        # TODO: Consider exporting non armored files too.

        otf = export_gpg_otrust_to_file(
            exp_dir.joinpath("otrust.gpg-otrust"),
            **c_ctx.as_proc_auth_dict())

        _encrypt_file_for_all_enc_cases(exp_dir, otf)

        os.chmod(exp_dir, mode=0o555)

    return tmp_dir
