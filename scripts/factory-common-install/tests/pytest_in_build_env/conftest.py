import os
import pytest
import pathmagic  # noqa: F401


def pytest_runtest_setup(item):
    if "1" != os.environ.get("PKG_NIXOS_FACTORY_COMMON_INSTALL_IN_BUILD_ENV"):
        pytest.skip(
            "Should be run only from build environement. "
            "See `PKG_NIXOS_FACTORY_COMMON_INSTALL_IN_BUILD_ENV`.")