from pathlib import Path

from ._export_impl import (
    _export_gpg_keys_by_id_to_file,
    _export_gpg_secret_keys_by_id_to_file,
    _export_gpg_otrust_to_file
)
from .auth import OptGpgAuthContext
from .process import OptGpgProcContextSoftT


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


def export_gpg_secret_subkeys_to_file(
        out_file_path: Path,
        email_or_id: str,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg private key to '{out_file_path}'.")
    return _export_gpg_secret_keys_by_id_to_file(
        "--export-secret-subkeys", out_file_path, email_or_id, auth_ctx, proc_ctx)


def export_gpg_otrust_to_file(
        out_file_path: Path,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    # print(f"Exporting gpg owner trust to '{out_file_path}'.")
    return _export_gpg_otrust_to_file(out_file_path, auth_ctx, proc_ctx)
