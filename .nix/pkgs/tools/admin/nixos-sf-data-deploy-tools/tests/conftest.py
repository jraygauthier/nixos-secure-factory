import os
import pytest
from _pytest.tmpdir import TempPathFactory
from pathlib import Path

from nsft_system_utils.file import write_text_file_content


@pytest.fixture(scope="module")
def src_tmp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("src")


@pytest.fixture(scope="module")
def src_tmp_dir_w_dummy_files(src_tmp_dir: Path) -> Path:
    fn = src_tmp_dir.joinpath("dummy.txt")
    write_text_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = src_tmp_dir.joinpath("dummy-ro.txt")
    write_text_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])

    dir = src_tmp_dir.joinpath("dummy-dir")
    os.mkdir(dir, mode=0o555)

    dir_ro = src_tmp_dir.joinpath("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    # Make these files and dirs ro to flag manip errors.
    os.chmod(fn, mode=0o444)
    os.chmod(fn_ro, mode=0o444)
    os.chmod(src_tmp_dir, mode=0o555)
    return src_tmp_dir


@pytest.fixture(scope="module")
def inexistant_src_file(src_tmp_dir_w_dummy_files: Path) -> Path:
    fn = src_tmp_dir_w_dummy_files.joinpath("does-not-exists.txt")
    return fn


@pytest.fixture(scope="module")
def dummy_src_file(src_tmp_dir_w_dummy_files: Path) -> Path:
    fn = src_tmp_dir_w_dummy_files.joinpath("dummy.txt")
    return fn


@pytest.fixture(scope="function")
def tgt_tmp_dir(tmp_path_factory: TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("tgt")


@pytest.fixture(scope="function")
def tgt_tmp_dir_w_dummy_files(tgt_tmp_dir: Path) -> Path:
    fn = tgt_tmp_dir.joinpath("dummy.txt")
    write_text_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = tgt_tmp_dir.joinpath("dummy-ro.txt")
    write_text_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])
    os.chmod(fn_ro, mode=0o444)

    dir = tgt_tmp_dir.joinpath("dummy-dir")
    os.mkdir(dir)

    dir_ro = tgt_tmp_dir.joinpath("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    return tgt_tmp_dir


@pytest.fixture(scope="function")
def dummy_tgt_file(tgt_tmp_dir_w_dummy_files: Path) -> Path:
    fn = tgt_tmp_dir_w_dummy_files.joinpath("dummy.txt")
    return fn


@pytest.fixture(scope="function")
def dummy_ro_tgt_file(tgt_tmp_dir_w_dummy_files: Path) -> Path:
    fn = tgt_tmp_dir_w_dummy_files.joinpath("dummy-ro.txt")
    return fn


@pytest.fixture(scope="function")
def inexistant_tgt_file(tgt_tmp_dir_w_dummy_files: Path) -> Path:
    fn = tgt_tmp_dir_w_dummy_files.joinpath("to-be-created-tgt.txt")
    return fn
