import os

from pathlib import Path

from nsft_system_utils.permissions import change_file_permissions, FilePermissionsOpts

from .process import run_gpg, OptGpgProcContextSoftT
from .auth import OptGpgAuthContext


def _create_gpg_parentdir_for_exported_file(
    out_file_path: Path,
) -> None:
    parent_dir = out_file_path.parent
    os.makedirs(parent_dir, 0o700, exist_ok=True)


def _export_gpg_keys_by_id_to_file(
        option: str,
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
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
        args, text=True, check=True, proc_ctx=proc_ctx, auth_ctx=auth_ctx)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _is_empty_passphrase_gpg_auth(auth_ctx: OptGpgAuthContext) -> bool:
    return auth_ctx is None or auth_ctx.passphrase is None or not auth_ctx.passphrase


def _export_gpg_secret_keys_by_id_to_file(
        option: str,
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    args = [
        "--batch",
        option,
        "--output", f"{out_file_path}",
        "--armor",
        f"{email_or_id}"
    ]

    if _is_empty_passphrase_gpg_auth(auth_ctx):
        run_gpg(
            args, text=True, check=True, proc_ctx=proc_ctx, auth_ctx=auth_ctx)
    else:
        assert auth_ctx is not None and auth_ctx.passphrase is not None
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
            args, text=True, input=auth_ctx.passphrase, check=True, proc_ctx=proc_ctx)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _export_gpg_info_to_file(
        option: str,
        out_file_path: Path,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    args = [
        "--batch",
        option,
        "--output", f"{out_file_path}"
    ]

    run_gpg(
        args, text=True, check=True, proc_ctx=proc_ctx, auth_ctx=auth_ctx)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def export_gpg_public_key_to_file(
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg public key to '{out_file_path}'.")
    return _export_gpg_keys_by_id_to_file(
        "--export", out_file_path, email_or_id, auth_ctx, proc_ctx)


def export_gpg_secret_keys_to_file(
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg private key to '{out_file_path}'.")
    return _export_gpg_secret_keys_by_id_to_file(
        "--export-secret-keys", out_file_path, email_or_id, auth_ctx, proc_ctx)


def export_gpg_otrust_to_file(
        out_file_path: Path,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg owner trust to '{out_file_path}'.")
    return _export_gpg_info_to_file(
        "--export-ownertrust", out_file_path, auth_ctx, proc_ctx)


def export_gpg_secret_subkeys_to_file(
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg private key to '{out_file_path}'.")
    return _export_gpg_secret_keys_by_id_to_file(
        "--export-secret-subkeys", out_file_path, email_or_id, auth_ctx, proc_ctx)
