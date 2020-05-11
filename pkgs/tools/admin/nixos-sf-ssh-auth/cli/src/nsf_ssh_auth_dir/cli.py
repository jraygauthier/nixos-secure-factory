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
    cwd: Path


def mk_default_cli_init_ctx() -> CliInitCtx:
    return CliInitCtx(
        cwd=Path.cwd()
    )


class _MkDefaultCliInitCtx:
    def __new__(cls) -> CliInitCtx:
        return mk_default_cli_init_ctx()


def ensure_cli_init_ctx(ctx: click.Context) -> CliInitCtx:
    out = ctx.ensure_object(_MkDefaultCliInitCtx)
    assert isinstance(out, CliInitCtx)
    return out


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
    ensure_cli_init_ctx(ctx)

    setup_verbose(1)


@cli.command()
@click.pass_context
def info(ctx: click.Context) -> None:
    """Print information about the current *ssh auth dir*."""
    init_ctx = ensure_cli_init_ctx(ctx)
    logging.info(f"info hello: {init_ctx.cwd}")


cli.add_command(user)
cli.add_command(group)
cli.add_command(git)


def mk_cli(init_ctx: Optional[CliInitCtx] = None) -> click.Command:
    if init_ctx is None:
        init_ctx = mk_default_cli_init_ctx()
    return cli(obj=init_ctx)


if __name__ == "__main__":
    mk_cli()
