# import os
# import pytest


def pytest_runtest_setup(item):
    pass
    """
    if "1" != os.environ.get("PKG_NIXOS_SF_FACTORY_INSTALL_IN_ENV"):
        pytest.skip(
            "Should be run only from build environement. "
            "See `PKG_NIXOS_SF_FACTORY_INSTALL_IN_ENV`.")
    """
