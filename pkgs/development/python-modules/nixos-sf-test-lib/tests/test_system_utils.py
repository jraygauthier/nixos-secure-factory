import logging
import os

import pytest

from nsft_system_utils import (get_file_mode, get_file_mode_simple, get_file_mode_simple_str,
                              get_file_mode_str, touch_file)


LOGGER = logging.getLogger(__name__)


@pytest.fixture(scope="function")
def temp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("test-tmp")

def test_touch_file(temp_dir) -> None:
    dummy_file = os.path.join(temp_dir, "dummy.txt")
    touch_file(dummy_file)
    assert os.path.exists(dummy_file)


def test_get_file_mode(temp_dir) -> None:
    dummy_file = os.path.join(temp_dir, "dummy.txt")
    touch_file(dummy_file)

    LOGGER.info("get_file_mode_str(%s): %s", dummy_file, get_file_mode_str(dummy_file))
    assert 0o100644 == get_file_mode(dummy_file)


def test_get_file_mode_simple(temp_dir) -> None:
    dummy_file = os.path.join(temp_dir, "dummy.txt")
    touch_file(dummy_file)

    LOGGER.info("get_file_mode_simple_str(%s): %s", dummy_file, get_file_mode_simple_str(dummy_file))
    assert 0o644 == get_file_mode_simple(dummy_file)
