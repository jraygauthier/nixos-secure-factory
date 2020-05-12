from nsf_factory_common_install.ssh_auth_dir import common_cli, device_specific_cli


def test_ssh_auth_dir_api():
    assert common_cli
    assert device_specific_cli
