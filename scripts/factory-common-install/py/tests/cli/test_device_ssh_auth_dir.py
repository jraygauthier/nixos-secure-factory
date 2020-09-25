from _pytest.logging import LogCaptureFixture

from nsf_factory_common_install.cli.device_ssh_auth_dir import cli
from test_lib.click import invoke_cli


def test_help(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['--help'])
    assert 0 == result.exit_code


def test_info(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['info'])
    assert 0 == result.exit_code
