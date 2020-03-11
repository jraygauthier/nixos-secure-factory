import os
import subprocess
from dataclasses import dataclass
from subprocess import PIPE, CompletedProcess, Popen, CalledProcessError
from typing import ContextManager, Dict, Iterator, List, Optional, Tuple, Union


@dataclass
class GpgContext:
    exe: str
    home_dir: str


@dataclass
class GpgContextWExpandedPaths(GpgContext):
    pass


# TODO: Use `TypedDict` on py 3.8.
GpgContextDictT = Dict[str, Optional[str]]
GpgContextTupleT = Tuple[Optional[str], Optional[str]]

GpgContextSoftT = Union[GpgContext, GpgContextDictT, GpgContextTupleT]
OptGpgContextSoftT = Optional[GpgContextSoftT]

_OptArgs = Optional[List[str]]


def get_default_gpg_context() -> GpgContextWExpandedPaths:
    return GpgContextWExpandedPaths("gpg", os.path.expanduser("~/.gnupg"))


def _expand_gpg_context_paths(gpg_ctx: GpgContext) -> GpgContextWExpandedPaths:
    return GpgContextWExpandedPaths(gpg_ctx.exe, os.path.expanduser(gpg_ctx.home_dir))


def ensure_gpg_context(
        gpg_ctx: OptGpgContextSoftT
) -> GpgContextWExpandedPaths:
    if isinstance(gpg_ctx, GpgContext):
        return _expand_gpg_context_paths(gpg_ctx)

    if gpg_ctx is None:
        return get_default_gpg_context()

    if isinstance(gpg_ctx, dict):
        exe = gpg_ctx['exe']
        home_dir = gpg_ctx['home_dir']
        assert exe is None or isinstance(exe, str)
        assert home_dir is None or isinstance(home_dir, str)
        return ensure_gpg_context((exe, home_dir))

    exe, home_dir = gpg_ctx
    if exe is None:
        exe = get_default_gpg_context().exe
    if home_dir is None:
        home_dir = get_default_gpg_context().home_dir
    return _expand_gpg_context_paths(GpgContext(exe, home_dir))


def _mk_gpg_args(
        extra_args: _OptArgs = None,
        gpg_ctx: OptGpgContextSoftT = None
) -> List[str]:
    if extra_args is None:
        extra_args = []

    gpg_ctx = ensure_gpg_context(gpg_ctx)

    return [
        gpg_ctx.exe,
        f"--homedir", gpg_ctx.home_dir
    ] + extra_args


def gpg_popen(
        args: _OptArgs = None,
        gpg_ctx: OptGpgContextSoftT = None,
        **kwargs
) -> ContextManager[Popen]:
    args = _mk_gpg_args(args, gpg_ctx)
    return subprocess.Popen(args, **kwargs)


def gpg_stdout_it(
        args: _OptArgs = None,
        gpg_ctx: OptGpgContextSoftT = None,
        **kwargs
) -> Iterator[str]:
    assert 'stdout' not in kwargs
    assert 'text' not in kwargs

    with gpg_popen(
            args, gpg_ctx=gpg_ctx,
            text=True, stdout=PIPE, **kwargs) as p:
        try:
            for l in p.stdout.readlines():
                yield l.rstrip()
        except KeyboardInterrupt:
            p.kill()
            raise
        except Exception:
            p.kill()
            raise

        retcode = p.poll()
        if retcode:
            raise CalledProcessError(retcode, p.args,
                                     output=None, stderr=None)


def run_gpg(
        args: _OptArgs,
        gpg_ctx: OptGpgContextSoftT = None,
        **kwargs
) -> CompletedProcess:
    args = _mk_gpg_args(args, gpg_ctx)
    return subprocess.run(args, **kwargs)
