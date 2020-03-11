
import textwrap
from typing import Optional

from .home_dir import create_and_assign_proper_permissions_to_gpg_home_dir
from .process import OptGpgProcContextSoftT, run_gpg
from .auth import OptGpgAuthContext


def create_gpg_secret_identity(
        email: str,
        user_name: str,
        auth_ctx: OptGpgAuthContext,
        expire_in: Optional[str] = None,
        proc_ctx: OptGpgProcContextSoftT = None
) -> None:
    if auth_ctx is None or auth_ctx.passphrase is None:
        passphrase = ""
    else:
        passphrase = auth_ctx.passphrase

    expire_in = expire_in or "1y"

    # print("Creating gpg identity with signing subkey")

    create_and_assign_proper_permissions_to_gpg_home_dir(
        proc_ctx=proc_ctx
    )

    cipher_preferences = (
        "SHA512 SHA384 SHA256 SHA224 AES256 AES192 "
        "AES CAST5 ZLIB BZIP2 ZIP Uncompressed")

    batch_script = textwrap.dedent(f'''\
        %no-protection
        Key-Type: RSA
        Key-Length: 4096
        Key-Usage: cert, sign
        Subkey-Type: RSA
        Subkey-Length: 4096
        Subkey-Usage: cert, encrypt
        Name-Real: {user_name}
        Name-Email: {email}
        Expire-Date: {expire_in}
        Preferences: {cipher_preferences}\
    ''')

    args = [
        "--batch",
        "--passphrase", passphrase,
        "--full-generate-key", "-"
    ]

    run_gpg(
        args, text=True, check=True,
        input=batch_script, proc_ctx=proc_ctx)
