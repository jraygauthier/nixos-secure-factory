import sys
import click
import logging

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .cli_user import user
from .cli_group import group
from .cli_git import git


@dataclass
class CliInitCtx:
    # The *ssh auth dir* over which to operate.
    cwd: Path
    # The current user's id if available.
    user_id: Optional[str]


def mk_default_cli_init_ctx() -> CliInitCtx:
    return CliInitCtx(
        cwd=Path.cwd(),
        user_id=None
    )


class _MkDefaultCliInitCtx:
    def __new__(cls) -> CliInitCtx:
        return mk_default_cli_init_ctx()


def ensure_cli_init_ctx(ctx: click.Context) -> CliInitCtx:
    if ctx.obj is not None:
        assert isinstance(ctx.obj, CliInitCtx)
        return ctx.obj
    # out = ctx.ensure_object(_MkDefaultCliInitCtx)
    # assert isinstance(out, CliInitCtx)
    return mk_default_cli_init_ctx()


def setup_verbose(
        verbose: int) -> None:
    verbosity_mapping = {
        0: logging.WARNING,
        1: logging.INFO,
        2: logging.DEBUG,
    }
    assert verbose >= 0
    logging.basicConfig(
        level=verbosity_mapping.get(verbose, logging.DEBUG))


@click.group()
@click.pass_context
def cli(ctx: click.Context) -> None:
    """Ssh authorization tool for nixos-secure-factory.

    All commands operate on the current *ssh auth dir* which
    by default correspond to the *current working directory*.
    """

    # assert ctx.obj is not None

    # ensure_cli_init_ctx(ctx)

    if ctx.obj:
        logging.warning(f"user_id: {ctx.obj.user_id}")

    setup_verbose(1)


@cli.command()
@click.pass_context
def info(ctx: click.Context) -> None:
    """Print information about the current *ssh auth dir*."""

    init_ctx = ensure_cli_init_ctx(ctx)

    print(f"cwd: '{init_ctx.cwd}'")
    if init_ctx.user_id is not None:
        print(f"user-id: '{init_ctx.user_id}'")


cli.add_command(user)
cli.add_command(group)
cli.add_command(git)


def run_cli(init_ctx: Optional[CliInitCtx] = None) -> None:
    if init_ctx is None:
        init_ctx = mk_default_cli_init_ctx()
    sys.exit(cli(obj=init_ctx))


if __name__ == "__main__":
    run_cli()
