import click
from _pytest.logging import LogCaptureFixture
from click.testing import CliRunner, Result
from typing import Optional, Iterable, Union, Mapping, IO, Any


def invoke_cli(
        caplog: LogCaptureFixture,
        cli: click.BaseCommand,
        args: Union[str, Iterable[str], None] = None,
        input: Optional[IO] = None,
        env: Optional[Mapping[str, str]] = None,
        catch_exceptions: bool = False,
        color: bool = False,
        mix_stderr: bool = False,
        **extra: Any
) -> Result:
    runner = CliRunner()
    with caplog.at_level(100000):  # click/issues/824 workaround
        out = runner.invoke(
            cli, args, input,
            env=env,
            catch_exceptions=catch_exceptions,
            color=color,
            mix_stderr=mix_stderr,
            **extra
        )
    return out
