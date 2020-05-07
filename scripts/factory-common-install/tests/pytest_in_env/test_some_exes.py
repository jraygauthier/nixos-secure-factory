
import os
import logging
import subprocess
import pytest

from bash_utils import sanitize_bash_path_out


LOGGER = logging.getLogger(__name__)


def setup_module(module):
    pass


def test_get_factory_common_install_libexec_dir():
    fci_libexec_dir = sanitize_bash_path_out(subprocess.check_output(
        "pkg-nixos-sf-factory-common-install-get-libexec-dir")
    )
    LOGGER.info("fci_libexec_dir: %s", fci_libexec_dir)
    assert os.path.exists(fci_libexec_dir)
