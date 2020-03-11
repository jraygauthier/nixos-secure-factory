
import logging
import subprocess
import pytest

from nsft_pgp_utils.query import list_gpg_keys

from test_lib.gpg_ctx import GpgContextWInfo

LOGGER = logging.getLogger(__name__)


def test_list_gpg_keys_on_ro_gpg_home(gpg_ctx_w_secret_id_ro: GpgContextWInfo) -> None:
    # This is a known gpg bug.
    # See [gnupg - gpg list keys error trustdb is not writable - Stack
    # Overflow](https://stackoverflow.com/questions/41916857/gpg-list-keys-error-trustdb-is-not-writable)

    with pytest.raises(subprocess.CalledProcessError):
        list_gpg_keys(gpg_ctx_w_secret_id_ro.proc)


def test_list_gpg_keys(gpg_ctx_w_secret_id: GpgContextWInfo) -> None:
    keys = list_gpg_keys(gpg_ctx_w_secret_id.proc)
    LOGGER.info(f"keys: {keys}")
