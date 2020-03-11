
import textwrap
from typing import Optional

from .process import OptGpgContextSoftT, run_gpg
from .home_dir import create_and_assign_proper_permissions_to_gpg_home_dir


def create_gpg_master_identity_with_signing_subkey(
        email: str,
        user_name: str,
        passphrase: Optional[str],
        expire_in: Optional[str] = None,
        gpg_ctx: OptGpgContextSoftT = None
) -> None:
    passphrase = passphrase or ""
    expire_in = expire_in or "1y"

    create_and_assign_proper_permissions_to_gpg_home_dir(
        gpg_ctx=gpg_ctx
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
        input=batch_script, gpg_ctx=gpg_ctx)
