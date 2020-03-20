from nsft_system_utils.permissions import get_file_permissions
from nsft_pgp_utils.ctx_proc_types import GpgProcContextExp


def check_minimal_gpg_home_dir_empty(proc: GpgProcContextExp) -> None:
    assert proc.home_dir.exists() and proc.home_dir.is_dir()
    hd_perms = get_file_permissions(proc.home_dir)
    assert 0o700 == hd_perms.mode_simple
    pk_dir = proc.home_dir.joinpath("private-keys-v1.d")
    assert pk_dir.exists() and pk_dir.is_dir()
    pkd_perms = get_file_permissions(pk_dir)
    assert 0o700 == pkd_perms.mode_simple


def check_minimal_gpg_home_dir_w_secret_id(proc: GpgProcContextExp) -> None:
    check_minimal_gpg_home_dir_empty(proc)

    pk_dir = proc.home_dir.joinpath("private-keys-v1.d")
    assert 1 <= len(list(pk_dir.glob("*.key")))
    assert proc.home_dir.joinpath("pubring.kbx").exists()
    assert proc.home_dir.joinpath("trustdb.gpg").exists()

    rev_dir = proc.home_dir.joinpath("openpgp-revocs.d")
    assert rev_dir.exists()
    revd_perms = get_file_permissions(rev_dir)
    assert 0o700 == revd_perms.mode_simple

    assert 1 <= len(list(rev_dir.glob("*.rev")))
