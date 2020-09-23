
import os
import logging
import subprocess

from bash_utils import sanitize_bash_path_out


LOGGER = logging.getLogger(__name__)


def setup_module(module):
    pass


def test_get_factory_common_install_sh_lib_dir():
    fci_sh_lib_dir = sanitize_bash_path_out(subprocess.check_output(
        "pkg-nsf-factory-common-install-get-sh-lib-dir")
    )
    LOGGER.info("fci_sh_lib_dir: %s", fci_sh_lib_dir)
    assert os.path.exists(fci_sh_lib_dir)
