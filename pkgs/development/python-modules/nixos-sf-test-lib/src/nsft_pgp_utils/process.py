import sys
from dataclasses import dataclass
from subprocess import (
    PIPE,
    CalledProcessError,
    CompletedProcess,
    Popen,
    TimeoutExpired,
    run,
)
from typing import Any, ContextManager, Dict, Iterator, List, Optional, Tuple

from .ctx_auth_types import OptGpgAuthContext
from .ctx_proc_types import OptGpgProcContextSoftT, ensure_gpg_proc_ctx
from .errors import GpgProcessError

_OptArgs = Optional[List[str]]


def _mk_gpg_cmd_and_args(
        extra_args: _OptArgs = None,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
) -> List[str]:
    if extra_args is None:
        extra_args = []

    proc = ensure_gpg_proc_ctx(proc)

    out = [
        str(proc.exe),
        f"--homedir", str(proc.home_dir)
    ]

    if auth is not None and auth.passphrase is not None:
        out.extend([
            "--passphrase", auth.passphrase
        ])

    out.extend(extra_args)
    return out


def gpg_popen(
        args: _OptArgs = None,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> ContextManager[Popen]:
    cmd_and_args = _mk_gpg_cmd_and_args(args, proc, auth)
    try:
        return Popen(cmd_and_args, **kwargs)
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e


def gpg_stdout_it(
        args: _OptArgs = None,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> Iterator[str]:
    assert 'stdout' not in kwargs
    assert 'text' not in kwargs

    try:
        with gpg_popen(
                args, proc=proc,
                auth=auth,
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
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e


def run_gpg(
        args: _OptArgs,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> CompletedProcess:
    cmd_and_args = _mk_gpg_cmd_and_args(args, proc, auth)
    try:
        return run(cmd_and_args, **kwargs)
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e


def check_gpg_output(
        args: _OptArgs,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> str:
    assert 'stdout' not in kwargs
    assert 'check' not in kwargs
    cmd_and_args = _mk_gpg_cmd_and_args(args, proc, auth)
    try:
        return run(cmd_and_args, check=True, stdout=PIPE, **kwargs).stdout
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e


@dataclass
class _RunLikeInputs:
    kwargs: Dict[str, Any]
    in_kwargs: Dict[str, Any]
    out_kwargs: Dict[str, Any]
    communicate_args: Tuple[Optional[str], Optional[float], bool]


# The first part of `subprocess.run`.
# Allow one to implement run like composite pipelines.
# Return the 3 last inputs of `_communicate_run_impl`.
def _process_run_like_kwargs(
        input: Optional[str] = None,
        capture_output: bool = False,
        timeout: Optional[float] = None,
        check: bool = False,
        **kwargs
) -> _RunLikeInputs:
    in_kwargs = dict()

    if input is not None:
        if kwargs.get('stdin') is not None:
            raise ValueError('stdin and input arguments may not both be used.')
        in_kwargs['stdin'] = PIPE

    out_kwargs = dict()

    if capture_output:
        if kwargs.get('stdout') is not None or kwargs.get('stderr') is not None:
            raise ValueError('stdout and stderr arguments may not be used '
                             'with capture_output.')
        out_kwargs['stdout'] = PIPE
        out_kwargs['stderr'] = PIPE

    for k in ['stdin', 'stdout', 'stderr']:
        try:
            del kwargs[k]
        except KeyError:
            pass

    # All keys should have been handled as in or out here.
    assert not kwargs

    return _RunLikeInputs(
        kwargs=kwargs,
        in_kwargs=in_kwargs,
        out_kwargs=out_kwargs,
        communicate_args=(input, timeout, check)
    )


# The last part of `subprocess.run`.
# Allow one to implement run like composite pipelines.
# Its 3 last inputs match the return of `_process_run_like_kwargs`.
def _communicate_run_impl(
        process: Popen,
        input: Optional[str] = None,
        timeout: Optional[float] = None,
        check: bool = False
) -> CompletedProcess:
    try:
        stdout, stderr = process.communicate(input, timeout=timeout)
    except TimeoutExpired as exc:
        process.kill()
        if "win32" == sys.platform:
            exc.stdout, exc.stderr = process.communicate()
        else:
            process.wait()
        raise
    except KeyboardInterrupt:
        process.kill()
        raise
    except Exception:
        process.kill()
        raise

    retcode = process.poll()
    if check and retcode:
        raise CalledProcessError(retcode, process.args,
                                 output=stdout, stderr=stderr)
    return CompletedProcess(process.args, retcode, stdout, stderr)


def run_precmd_and_pipe_to_gpg(
        pre_cmd: str,
        pre_args: _OptArgs,
        args: _OptArgs,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> CompletedProcess:
    try:
        run_like_ins = _process_run_like_kwargs(**kwargs)

        if pre_args is None:
            pre_args = []

        pre_cmd_and_args = [pre_cmd]
        pre_cmd_and_args.extend(pre_args)
        pre_p = Popen(
            pre_cmd_and_args, stdout=PIPE, **run_like_ins.in_kwargs)

        cmd_and_args = _mk_gpg_cmd_and_args(args, proc, auth)

        assert not run_like_ins.kwargs
        with Popen(
                cmd_and_args,
                stdin=pre_p.stdout,
                **run_like_ins.out_kwargs) as gpg_p:
            pre_p.stdout.close()
            out = _communicate_run_impl(gpg_p, *run_like_ins.communicate_args)
        return out
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e


def run_gpg_and_pipe_to_postcmd(
        post_cmd: str,
        post_args: _OptArgs,
        args: _OptArgs,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
        **kwargs
) -> CompletedProcess:
    try:
        run_like_ins = _process_run_like_kwargs(**kwargs)
        cmd_and_args = _mk_gpg_cmd_and_args(args, proc, auth)

        assert not run_like_ins.kwargs
        gpg_p = Popen(
            cmd_and_args, stdout=PIPE, **run_like_ins.in_kwargs)

        if post_args is None:
            post_args = []

        post_cmd_and_args = [post_cmd]
        post_cmd_and_args.extend(post_args)

        with Popen(
                post_cmd_and_args,
                stdin=gpg_p.stdout,
                **run_like_ins.out_kwargs) as post_p:
            gpg_p.stdout.close()
            out = _communicate_run_impl(post_p, *run_like_ins.communicate_args)
        return out
    except CalledProcessError as e:
        raise GpgProcessError.mk_from(e) from e
