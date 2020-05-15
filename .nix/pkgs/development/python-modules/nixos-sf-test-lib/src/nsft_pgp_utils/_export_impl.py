from pathlib import Path

from nsft_system_utils.permissions import change_file_permissions, FilePermissionsOpts

from .process import run_gpg, check_gpg_output
from .ctx_proc_types import OptGpgProcContextSoftT
from .ctx_auth_types import OptGpgAuthContext


def _create_gpg_parentdir_for_exported_file(
    out_file_path: Path,
) -> None:
    out_file_path.parent.mkdir(
        0o700, parents=True, exist_ok=True)


def _export_gpg_keys_by_id_to_file(
        option: str,
        out_file_path: Path,
        email_or_id: str,
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    args = [
        "--batch",
        option,
        "--output", f"{out_file_path}",
        "--armor",
        f"{email_or_id}"
    ]

    run_gpg(
        args, text=True, check=True, proc=proc, auth=auth)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _export_gpg_keys_by_id_to_str(
        option: str,
        email_or_id: str,
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> str:
    args = [
        "--batch",
        option,
        "--armor",
        f"{email_or_id}"
    ]

    out_str = check_gpg_output(
        args, text=True, proc=proc, auth=auth)

    return out_str


def _is_empty_passphrase_gpg_auth(auth: OptGpgAuthContext) -> bool:
    return auth is None or auth.passphrase is None or not auth.passphrase


def _export_gpg_secret_keys_by_id_to_file(
        option: str,
        out_file_path: Path,
        email_or_id: str,
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    args = [
        "--batch",
        option,
        "--output", f"{out_file_path}",
        "--armor",
        f"{email_or_id}"
    ]

    if _is_empty_passphrase_gpg_auth(auth):
        run_gpg(
            args, text=True, check=True, proc=proc, auth=auth)
    else:
        assert auth is not None and auth.passphrase is not None
        # For some reason, when "passphrase" is non empty, when using
        # secret export option, we're prompted for a password by gui even
        # tough "--passphrase" is specified. This is a workaround.
        args.extend([
            "--pinentry-mode", "loopback",
            "--yes",
            "--no-tty",
            "--passphrase-fd", "0"
        ])

        run_gpg(
            args, text=True, input=auth.passphrase, check=True, proc=proc)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _export_gpg_info_to_str(
        option: str,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> str:
    args = [
        "--batch",
        option,
    ]

    out_str = check_gpg_output(
        args, text=True, proc=proc, auth=auth)

    return out_str


def _export_gpg_info_to_file(
        option: str,
        out_file_path: Path,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    out_str = _export_gpg_info_to_str(
        option, proc=proc, auth=auth)

    with open(out_file_path, "w") as f:
        f.write(out_str)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _export_gpg_otrust_to_str(
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> str:
    return _export_gpg_info_to_str(
        "--export-ownertrust", auth, proc)


def _export_gpg_otrust_to_file(
        out_file_path: Path,
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    return _export_gpg_info_to_file(
        "--export-ownertrust", out_file_path, auth, proc)
