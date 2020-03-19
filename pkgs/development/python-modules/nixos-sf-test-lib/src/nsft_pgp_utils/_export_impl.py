from pathlib import Path

from nsft_system_utils.permissions import change_file_permissions, FilePermissionsOpts

from .process import run_gpg, OptGpgProcContextSoftT, check_gpg_output
from .auth import OptGpgAuthContext


def _create_gpg_parentdir_for_exported_file(
    out_file_path: Path,
) -> None:
    out_file_path.parent.mkdir(
        0o700, parents=True, exist_ok=True)


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


def _export_gpg_info_to_str(
        option: str,
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None
) -> str:
    args = [
        "--batch",
        option,
    ]

    out_str = check_gpg_output(
        args, text=True, proc_ctx=proc_ctx, auth_ctx=auth_ctx)

    return out_str


def _export_gpg_info_to_file(
        option: str,
        out_file_path: Path,
        auth_ctx: OptGpgAuthContext = None,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    _create_gpg_parentdir_for_exported_file(out_file_path)

    out_str = _export_gpg_info_to_str(
        option, proc_ctx=proc_ctx, auth_ctx=auth_ctx)

    with open(out_file_path, "w") as f:
        f.write(out_str)

    change_file_permissions(
        out_file_path,
        FilePermissionsOpts(mode=0o700))

    return out_file_path


def _export_gpg_otrust_to_str(
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> str:
    return _export_gpg_info_to_str(
        "--export-ownertrust", auth_ctx, proc_ctx)


def _export_gpg_otrust_to_file(
        out_file_path: Path,
        auth_ctx: OptGpgAuthContext,
        proc_ctx: OptGpgProcContextSoftT = None
) -> Path:
    return _export_gpg_info_to_file(
        "--export-ownertrust", out_file_path, auth_ctx, proc_ctx)
