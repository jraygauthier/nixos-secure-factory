import logging
import os

from nsft_shell_utils import call_sh_module_fn

from test_lib.env import are_package_propagated_dependencies_installed

LOGGER = logging.getLogger(__name__)


def _get_shlib_dir() -> str:
    return os.path.abspath(os.path.join(
        os.path.dirname(__file__),
        "../../sh-lib"))


def _get_sh_module() -> str:
    return os.path.join(_get_shlib_dir(), "deploy-tools.sh")


def _call_sh_module_fn(fn_name: str, *args, **kwargs) -> None:
    call_sh_module_fn(_get_sh_module(), fn_name, *args, **kwargs)


def test_propagated_dependencies_installed():
    assert are_package_propagated_dependencies_installed()


def test_module_sourced() -> None:
    _call_sh_module_fn("true")