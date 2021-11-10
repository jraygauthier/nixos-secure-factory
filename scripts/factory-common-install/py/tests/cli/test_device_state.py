from _pytest.logging import LogCaptureFixture

from nsf_factory_common_install.cli.device_state import cli
from test_lib.click import invoke_cli


def test_help(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['--help'])
    assert 0 == result.exit_code


def test_info(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['info'])
    assert 0 == result.exit_code


def test_device_state_checkout_with_device_identifier(
        caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['checkout', 'qc-zilia-test-a11aa'], input='y\n')
    assert 0 == result.exit_code

def test_device_state_checkout_with_sn(
        caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['checkout', '--serial-number', '100001'], input='y\n')
    assert 0 == result.exit_code