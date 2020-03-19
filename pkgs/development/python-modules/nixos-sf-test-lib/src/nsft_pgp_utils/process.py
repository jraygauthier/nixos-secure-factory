import subprocess
from pathlib import Path
from dataclasses import dataclass
from subprocess import PIPE, CompletedProcess, Popen, CalledProcessError
from typing import ContextManager, Dict, Iterator, List, Optional, Tuple, Union
from .auth import OptGpgAuthContext


@dataclass
class GpgProcContextOpt:
    exe: Optional[Path]
    home_dir: Optional[Path]


@dataclass
class GpgProcContext:
    exe: Path
    home_dir: Path


@dataclass
class GpgProcContextExp(GpgProcContext):
    pass


# TODO: Use `TypedDict` on py 3.8.
GpgProcContextDictT = Dict[str, Optional[Path]]
GpgProcContextTupleT = Tuple[Optional[Path], Optional[Path]]

GpgProcContextSoftT = Union[
    GpgProcContext, GpgProcContextOpt, GpgProcContextDictT, GpgProcContextTupleT]
OptGpgProcContextSoftT = Optional[GpgProcContextSoftT]

_OptArgs = Optional[List[str]]


def get_default_gpg_context() -> GpgProcContextExp:
    return GpgProcContextExp(Path("gpg"), Path("~/.gnupg").expanduser())


def _expand_gpg_context_paths(
        proc_ctx: GpgProcContext) -> GpgProcContextExp:
    return GpgProcContextExp(
        proc_ctx.exe, proc_ctx.home_dir.expanduser())


def _fill_gpg_context_missing_fields(
        ctx: GpgProcContextOpt) -> GpgProcContextExp:
    exe = ctx.exe
    home_dir = ctx.home_dir

    assert exe is None or isinstance(exe, Path)
    assert home_dir is None or isinstance(home_dir, Path)

    if exe is None:
        exe = get_default_gpg_context().exe
    if home_dir is None:
        home_dir = get_default_gpg_context().home_dir

    return _expand_gpg_context_paths(GpgProcContext(exe, home_dir))


def ensure_gpg_context(
        proc_ctx: OptGpgProcContextSoftT
) -> GpgProcContextExp:
    if isinstance(proc_ctx, GpgProcContext):
        return _expand_gpg_context_paths(proc_ctx)

    if proc_ctx is None:
        return get_default_gpg_context()

    if isinstance(proc_ctx, dict):
        return _fill_gpg_context_missing_fields(GpgProcContextOpt(**proc_ctx))

    if isinstance(proc_ctx, tuple):
        return _fill_gpg_context_missing_fields(GpgProcContextOpt(*proc_ctx))

    return _fill_gpg_context_missing_fields(proc_ctx)


def _mk_gpg_args(
        extra_args: _OptArgs = None,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
) -> List[str]:
    if extra_args is None:
        extra_args = []

    proc_ctx = ensure_gpg_context(proc_ctx)

    out = [
        str(proc_ctx.exe),
        f"--homedir", str(proc_ctx.home_dir)
    ]

    if auth_ctx is not None and auth_ctx.passphrase is not None:
        out.extend([
            "--passphrase", auth_ctx.passphrase
        ])

    out.extend(extra_args)
    return out


def gpg_popen(
        args: _OptArgs = None,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
        **kwargs
) -> ContextManager[Popen]:
    args = _mk_gpg_args(args, proc_ctx, auth_ctx)
    return subprocess.Popen(args, **kwargs)


def gpg_stdout_it(
        args: _OptArgs = None,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
        **kwargs
) -> Iterator[str]:
    assert 'stdout' not in kwargs
    assert 'text' not in kwargs

    with gpg_popen(
            args, proc_ctx=proc_ctx,
            auth_ctx=auth_ctx,
            text=True, stdout=PIPE,
            **kwargs) as p:
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
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
        **kwargs
) -> CompletedProcess:
    args = _mk_gpg_args(args, proc_ctx, auth_ctx)
    return subprocess.run(args, **kwargs)


def check_gpg_output(
        args: _OptArgs,
        proc_ctx: OptGpgProcContextSoftT = None,
        auth_ctx: OptGpgAuthContext = None,
        **kwargs
) -> str:
    assert 'stdout' not in kwargs
    assert 'check' not in kwargs
    args = _mk_gpg_args(args, proc_ctx, auth_ctx)
    return subprocess.run(args, check=True, stdout=PIPE, **kwargs).stdout
