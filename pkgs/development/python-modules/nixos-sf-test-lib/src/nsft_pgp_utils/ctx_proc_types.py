from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional, Tuple, Union


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


def mk_gpg_proc_ctx_for_user_home_dir(user_home_dir: Path) -> GpgProcContextExp:
    gpg_home_dir = user_home_dir.joinpath(".gnupg")
    return ensure_gpg_proc_ctx((None, gpg_home_dir))


def get_default_gpg_proc_ctx() -> GpgProcContextExp:
    return GpgProcContextExp(Path("gpg"), Path("~/.gnupg").expanduser())


def _expand_gpg_proc_context_paths(
        proc: GpgProcContext) -> GpgProcContextExp:
    return GpgProcContextExp(
        proc.exe, proc.home_dir.expanduser())


def _fill_gpg_proc_context_missing_fields(
        ctx: GpgProcContextOpt) -> GpgProcContextExp:
    exe = ctx.exe
    home_dir = ctx.home_dir

    assert exe is None or isinstance(exe, Path)
    assert home_dir is None or isinstance(home_dir, Path)

    if exe is None:
        exe = get_default_gpg_proc_ctx().exe
    if home_dir is None:
        home_dir = get_default_gpg_proc_ctx().home_dir

    return _expand_gpg_proc_context_paths(GpgProcContext(exe, home_dir))


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
