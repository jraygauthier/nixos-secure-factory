from typing import Dict, Any, List

import pytest
import subprocess
import logging
import os

from nsft_shell_utils import call_sh_module_fn

from test_lib.dummy import my_dummy_fn

LOGGER = logging.getLogger(__name__)


def _get_shlib_dir() -> str:
    return os.path.abspath(os.path.join(
        os.path.dirname(__file__),
        "../../sh-lib"))

def _get_sh_module() -> str:
    return os.path.join(_get_shlib_dir(), "deploy-tools.sh")


# pytestmark = [
#     pytest.mark.skipif(
#         not os.path.exists(_get_sh_module()),
#         reason=("Cannot find sh module at expected location: {}".format(_get_sh_module())))
# ]


def _call_sh_module_fn(fn_name: str, *args, **kwargs) -> None:
    call_sh_module_fn(_get_sh_module(), fn_name, *args, **kwargs)


def test_module_sourced() -> None:
    _call_sh_module_fn("true")