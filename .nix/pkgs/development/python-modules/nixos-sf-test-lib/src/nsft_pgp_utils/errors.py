
import shlex
from typing import Optional, List, Union
from subprocess import CalledProcessError


class GpgError(Exception):
    pass


_CmdT = Union[str, List[str]]


def _format_cmd(cmd: _CmdT) -> str:
    if isinstance(cmd, str):
        return cmd

    if not isinstance(cmd, list):
        return f"{cmd}"

    return " ".join(map(lambda x: shlex.quote(x), cmd))


class GpgProcessError(GpgError):
    @classmethod
    def mk_from(cls, other: CalledProcessError) -> 'GpgProcessError':
        return GpgProcessError(**other.__dict__)

    def __init__(
            self,
            returncode: int,
            cmd: _CmdT,
            output: Optional[str] = None,
            stderr: Optional[str] = None
    ) -> None:
        cmd_str = _format_cmd(cmd)
        self._impl = CalledProcessError(returncode, cmd_str, output, stderr)
        self._cmd = cmd

    def __str__(self) -> str:
        return self._impl.__str__()

    @property
    def returncode(self) -> int:
        return self._impl.returncode

    @property
    def cmd(self) -> _CmdT:
        return self._cmd

    @property
    def output(self) -> Optional[str]:
        return self._impl.output

    @property
    def stderr(self) -> Optional[str]:
        return self._impl.stderr

    @property
    def stdout(self) -> Optional[str]:
        return self._impl.output
