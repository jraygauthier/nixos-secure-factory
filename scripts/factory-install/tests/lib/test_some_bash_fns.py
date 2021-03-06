
import os
import logging
import subprocess

from bash_utils import sanitize_bash_path_out

LOGGER = logging.getLogger(__name__)


def setup_module(module):
    pass


def _get_fi_sh_lib_dir():
    return os.path.abspath(os.path.join(
        os.path.dirname(__file__),
        "../../sh-lib"))


def _get_cfi_sh_lib_dir():
    return sanitize_bash_path_out(subprocess.check_output(
        "pkg-nsf-factory-common-install-get-sh-lib-dir"))


def _get_fi_sh_module_path(name):
    return os.path.join(_get_fi_sh_lib_dir(), name)


def _get_cfi_sh_module_path(name):
    return os.path.join(_get_cfi_sh_lib_dir(), name)


def test_get_factory_common_install_sh_lib_dir():
    fci_sh_lib_dir = sanitize_bash_path_out(subprocess.check_output(
        "pkg-nsf-factory-common-install-get-sh-lib-dir")
    )
    LOGGER.info("fci_sh_lib_dir: %s", fci_sh_lib_dir)
    assert os.path.exists(fci_sh_lib_dir)


def test_my_bash_fn_test():
    LOGGER.info("hello")
    subprocess.check_output([
        "bash", "-c",
        "true",
        # "{}; {}".format(_get_fi_sh_module_path("tools.sh")),
        "--",
        ""
    ])
