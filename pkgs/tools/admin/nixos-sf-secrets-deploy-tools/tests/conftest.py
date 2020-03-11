
import os
import pytest

from nsft_system_utils import write_file_content, get_os_users, get_os_groups


@pytest.fixture(scope="module")
def src_tmp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("src")


@pytest.fixture(scope="module")
def src_tmp_dir_w_dummy_files(src_tmp_dir):
    fn = src_tmp_dir.join("dummy.txt")
    write_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = src_tmp_dir.join("dummy-ro.txt")
    write_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])

    dir = src_tmp_dir.join("dummy-dir")
    os.mkdir(dir, mode=0o555)

    dir_ro = src_tmp_dir.join("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    # Make these files and dirs ro to flag manip errors.
    os.chmod(fn, mode=0o444)
    os.chmod(fn_ro, mode=0o444)
    os.chmod(src_tmp_dir, mode=0o555)
    return src_tmp_dir


@pytest.fixture(scope="module")
def inexistant_src_file(src_tmp_dir_w_dummy_files):
    fn = src_tmp_dir_w_dummy_files.join("does-not-exists.txt")
    return fn


@pytest.fixture(scope="module")
def dummy_src_file(src_tmp_dir_w_dummy_files):
    fn = src_tmp_dir_w_dummy_files.join("dummy.txt")
    return fn


@pytest.fixture(scope="function")
def tgt_tmp_dir(tmpdir_factory):
    return tmpdir_factory.mktemp("tgt")


@pytest.fixture(scope="function")
def tgt_tmp_dir_w_dummy_files(tgt_tmp_dir):
    fn = tgt_tmp_dir.join("dummy.txt")
    write_file_content(fn, [
        "Dummy src file content.\n"
    ])

    fn_ro = tgt_tmp_dir.join("dummy-ro.txt")
    write_file_content(fn_ro, [
        "Dummy src file content.\n"
    ])
    os.chmod(fn_ro, mode=0o444)

    dir = tgt_tmp_dir.join("dummy-dir")
    os.mkdir(dir)

    dir_ro = tgt_tmp_dir.join("dummy-dir-ro")
    os.mkdir(dir_ro, mode=0o555)

    return tgt_tmp_dir



@pytest.fixture(scope="function")
def dummy_tgt_file(tgt_tmp_dir_w_dummy_files):
    fn = tgt_tmp_dir_w_dummy_files.join("dummy.txt")
    return fn


@pytest.fixture(scope="function")
def dummy_ro_tgt_file(tgt_tmp_dir_w_dummy_files):
    fn = tgt_tmp_dir_w_dummy_files.join("dummy-ro.txt")
    return fn


@pytest.fixture(scope="function")
def inexistant_tgt_file(tgt_tmp_dir_w_dummy_files):
    fn = tgt_tmp_dir_w_dummy_files.join("to-be-created-tgt.txt")
    return fn
