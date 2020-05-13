from nsf_factory_common_install.cli_ssh_auth_dir import (
    run_cli_common,
    run_cli_device_specific,
)


def test_ssh_auth_dir_api():
    assert run_cli_common
    assert run_cli_device_specific
