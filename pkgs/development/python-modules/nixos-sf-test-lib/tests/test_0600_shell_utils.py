import subprocess
import pytest
import os

from nsft_system_utils.file import touch_file
from nsft_shell_utils.program import call_shell_program


def test_call_shell_program_true():
    out = call_shell_program("true")
    assert [] == out


def test_call_shell_program_false():
    with pytest.raises(subprocess.CalledProcessError):
        call_shell_program("false")


def test_call_shell_program_echo():
    out = call_shell_program("echo", "Hello", "World")
    assert ["Hello World"] == out


@pytest.fixture(scope="function")
def temp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("test-tmp")


@pytest.fixture(scope="function")
def dummy_tmp_file(temp_dir):
    dummy_file = os.path.join(temp_dir, "dummy.txt")
    touch_file(dummy_file)
    return dummy_file


def test_call_shell_program_test_e_success(dummy_tmp_file) -> None:
    out = call_shell_program("test", "-e", dummy_tmp_file)
    assert [] == out


def test_call_shell_program_test_e_failure(temp_dir) -> None:
    with pytest.raises(subprocess.CalledProcessError):
        call_shell_program("test", "-e", os.path.join(temp_dir, "does-not-exist.txt"))
