import click
from pathlib import Path
from typing import Optional
from dataclasses import dataclass


@dataclass
class CliCtx:
    # The state file stored in the configuration repository.
    state_file: Path
    # The state file checkout location if any.
    # If none, checkout won't be possible.
    # This file will be used for temporary / overrides edits when (
    # TBD, poss: `--override`)
    # flag is used.
    # Fields will be set in both the cfg and the override state file when no flag
    # specified and flags appear in both. That is unless the `--no-override` or
    # `--only-override` flags are used.
    # When not specified otherwise, field get will print this version when available.
    # Usually the ws version of the config.
    # This is also the checkout target location.
    override_state_file: Optional[Path]


def init_cli_ctx(
        ctx: click.Context, init_ctx: CliCtx
) -> CliCtx:
    assert ctx.obj is None
    ctx.obj = init_ctx
    return init_ctx


pass_cli_ctx = click.make_pass_decorator(CliCtx)
