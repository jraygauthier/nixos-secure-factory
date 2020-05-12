# import logging
from pathlib import Path
from _pytest.logging import LogCaptureFixture

from nsf_ssh_auth_dir.cli import cli, CliInitCtx
from test_lib.click import invoke_cli


def test_help(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['--help'])
    assert 0 == result.exit_code


def test_info(caplog: LogCaptureFixture) -> None:
    result = invoke_cli(caplog, cli, ['info'])
    assert 0 == result.exit_code


def test_info_w_init_ctx(caplog: LogCaptureFixture) -> None:
    init_ctx = CliInitCtx(cwd=Path("/my/path"), user_id="my_user_id")
    result = invoke_cli(caplog, cli, ['info'], obj=init_ctx)
    assert 0 == result.exit_code
    # logging.info(f"stdout:\n{result.output}")
    assert "/my/path" in result.output
    assert "my_user_id" in result.output
