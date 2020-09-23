import os
import pytest


def pytest_runtest_setup(item):
    if "1" != os.environ.get("PKG_NSF_FACTORY_COMMON_INSTALL_IN_BUILD_ENV"):
        pytest.skip(
            "Should be run only from build environement. "
            "See `PKG_NSF_FACTORY_COMMON_INSTALL_IN_BUILD_ENV`.")
