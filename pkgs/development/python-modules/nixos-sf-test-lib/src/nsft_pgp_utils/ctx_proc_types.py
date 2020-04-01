import os
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional, Tuple, Union, Any

_GpgEnvT = Dict[str, str]
_OptGpgEnvT = Optional[_GpgEnvT]


@dataclass
class GpgProcContextOpt:
    exe: Optional[Path]
    home_dir: Optional[Path]
    env: _OptGpgEnvT


@dataclass
class GpgProcContext:
    exe: Path
    home_dir: Path
    env: _GpgEnvT


@dataclass
class GpgProcContextExp(GpgProcContext):
    pass


# TODO: Use `TypedDict` on py 3.8.
GpgProcContextDictT = Dict[str, Any]
GpgProcContextTupleT = Tuple[Optional[Path], Optional[Path], _OptGpgEnvT]

GpgProcContextSoftT = Union[
    GpgProcContext, GpgProcContextOpt, GpgProcContextDictT, GpgProcContextTupleT]
OptGpgProcContextSoftT = Optional[GpgProcContextSoftT]


def mk_gpg_proc_ctx_for_user_home_dir(user_home_dir: Path) -> GpgProcContextExp:
    gpg_home_dir = user_home_dir.joinpath(".gnupg")
    return ensure_gpg_proc_ctx((None, gpg_home_dir, None))


def get_default_gpg_proc_ctx() -> GpgProcContextExp:
    try:
        # Attempt to use the gpg provided by env var. This is useful to prevent
        # interference with program under test as we want to test that the
        # program under test is packaged correctly without having us injecting
        # its gpg dependancy. This also makes a little gpg sandbox.
        env = {
            "PATH": os.environ["NIXOS_SF_TEST_LIB_BIN_PATH"]
        }
    except KeyError:
        env = {
            # Let it fail if `PATH` cannot be found as it will just fail later anyway..
            "PATH": os.environ["PATH"]
        }

    # We want to prevent at any costs any effect of this test lib on the user's
    # own gnupg home directory. All operations should be performed on temporary
    # gnupg home dirs.
    default_gnupg_homedir = "/homeless-shelter/.gnupg"

    env.update({
        "GNUPGHOME": default_gnupg_homedir
    })

    exe = Path("gpg")

    return GpgProcContextExp(exe, Path(default_gnupg_homedir).expanduser(), env)


def _expand_gpg_proc_context_paths(
        proc: GpgProcContext) -> GpgProcContextExp:
    return GpgProcContextExp(
        proc.exe, proc.home_dir.expanduser(), proc.env)


def _fill_gpg_proc_context_missing_fields(
        ctx: GpgProcContextOpt) -> GpgProcContextExp:
    exe = ctx.exe
    home_dir = ctx.home_dir
    env = ctx.env

    assert exe is None or isinstance(exe, Path)
    assert home_dir is None or isinstance(home_dir, Path)

    if exe is None:
        exe = get_default_gpg_proc_ctx().exe
    if home_dir is None:
        home_dir = get_default_gpg_proc_ctx().home_dir
    if env is None:
        env = get_default_gpg_proc_ctx().env

    return _expand_gpg_proc_context_paths(GpgProcContext(exe, home_dir, env))


def ensure_gpg_proc_ctx(
        proc: OptGpgProcContextSoftT = None
) -> GpgProcContextExp:
    if isinstance(proc, GpgProcContext):
        return _expand_gpg_proc_context_paths(proc)

    if proc is None:
        return get_default_gpg_proc_ctx()

    if isinstance(proc, dict):
        return _fill_gpg_proc_context_missing_fields(GpgProcContextOpt(**proc))

    if isinstance(proc, tuple):
        return _fill_gpg_proc_context_missing_fields(GpgProcContextOpt(*proc))

    return _fill_gpg_proc_context_missing_fields(proc)
