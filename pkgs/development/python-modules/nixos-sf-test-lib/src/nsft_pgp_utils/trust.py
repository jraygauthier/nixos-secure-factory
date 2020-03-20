from .ctx_proc_types import OptGpgProcContextSoftT
from .process import run_gpg
from .ctx_auth_types import OptGpgAuthContext
from .io_import import import_gpg_ui_otrust
from .key_types import GpgKeyWUIOwnerTrust
from .trust_types import GpgOwnerTrust


def trust_gpg_key(
    fpr: str,
    trust: GpgOwnerTrust,
    auth: OptGpgAuthContext = None,
    proc: OptGpgProcContextSoftT = None
) -> None:
    ui_otrust = [
        GpgKeyWUIOwnerTrust(fpr, trust),
    ]
    import_gpg_ui_otrust(
        ui_otrust,
        # auth=auth,
        proc=proc)


def sign_gpg_key(
    fpr: str,
    auth: OptGpgAuthContext = None,
    proc: OptGpgProcContextSoftT = None
) -> None:
    args = [
        "--batch",
        "--yes",
        "--quick-sign-key", f"{fpr}"
    ]

    run_gpg(
        args, text=True, check=True, auth=auth, proc=proc)


def sign_and_trust_gpg_key(
    fpr: str,
    trust: GpgOwnerTrust,
    auth: OptGpgAuthContext = None,
    proc: OptGpgProcContextSoftT = None
) -> None:
    sign_gpg_key(fpr, auth, proc)
    trust_gpg_key(fpr, trust, auth, proc)
