import logging
import os

import pytest
from _pytest.tmpdir import TempPathFactory
from pathlib import Path

from nsft_system_utils.permissions_simple import (
    get_file_mode,
    get_file_mode_simple,
    get_file_mode_simple_str,
    get_file_mode_str,
)
from nsft_system_utils.permissions import call_chmod
from nsft_system_utils.file import (
    touch_file,
)

LOGGER = logging.getLogger(__name__)


@pytest.fixture(scope="function")
def temp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("test-tmp")


def test_touch_file(temp_dir: Path) -> None:
    dummy_file = temp_dir.joinpath("dummy.txt")
    touch_file(dummy_file)
    assert os.path.exists(dummy_file)


def test_get_file_mode(temp_dir: Path) -> None:
    dummy_file = temp_dir.joinpath("dummy.txt")
    touch_file(dummy_file)

    LOGGER.info("get_file_mode_str(%s): %s", dummy_file, get_file_mode_str(dummy_file))
    assert 0o100644 == get_file_mode(dummy_file)


def test_get_file_mode_simple(temp_dir: Path) -> None:
    dummy_file = temp_dir.joinpath("dummy.txt")
    touch_file(dummy_file)

    LOGGER.info(
        "get_file_mode_simple_str(%s): %s",
        dummy_file, get_file_mode_simple_str(dummy_file))
    assert 0o644 == get_file_mode_simple(dummy_file)


def test_call_chmod(temp_dir: Path) -> None:
    dummy_file = temp_dir.joinpath("dummy.txt")
    touch_file(dummy_file)

    call_chmod(dummy_file, "a-w", recursive=True)
    assert 0o444 == get_file_mode_simple(dummy_file)
