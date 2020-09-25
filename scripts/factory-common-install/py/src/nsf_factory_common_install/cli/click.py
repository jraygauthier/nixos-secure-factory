"""A couple of click helpers.

These allow us to standardize how we output messages and errors
throughout the various nsf cli application.

Some of these also allow us to standardize some commonly used
patterns.
"""

import os
import sys
import click

from typing import Type, Optional, Any
from functools import update_wrapper


def _format_msg(msg: str, fg=None) -> str:
    """Format the a message with some colors

    The first line is printed in red whereas the remaining lines are
    left as were.
    """
    return "\n".join(
        click.style(l, fg=fg)
        if 0 == idx else l
        for idx, l in enumerate(msg.splitlines())
    )


def _format_error_msg(msg: str) -> str:
    """Format the error message with first line in red."""
    return _format_msg(msg, fg="red")


def _format_warning_msg(msg: str) -> str:
    """Format the warning message with first line in yellow."""
    return _format_msg(msg, fg="yellow")


class CliExit(click.exceptions.Exit):
    def __init__(self, code: int = 0) -> None:
        super().__init__(code)


class CliError(click.ClickException):
    def __init__(self, message: str) -> None:
        super().__init__(_format_error_msg(message))


class CliUsageError(click.UsageError):
    def __init__(self, message: str) -> None:
        super().__init__(
            _format_error_msg(message), click.get_current_context())


def _get_prog_name() -> str:
    return os.path.basename(sys.argv[0] if sys.argv else __file__)


def is_click_requesting_shell_completion():
    prog_name = _get_prog_name()

    complete_var = f"_{prog_name}_COMPLETE".replace("-", "_").upper()
    return os.environ.get(complete_var, None) is not None


def echo_error(msg: str) -> None:
    click.echo(f"Error: {_format_error_msg(msg)}", err=True)


def echo_warning(msg: str) -> None:
    click.echo(f"Warning: {_format_warning_msg(msg)}", err=True)


def find_ctx_dict_instance(
        ctx: click.Context, at_key: str, instance_type: Type) -> Optional[Any]:
    """Return the first `ctx.obj` of type `dict` containing
        an instance of specified type at specified key.

    This is an improvement over `click.Context.find_object`.
    """
    node: Optional[click.Context] = ctx
    while node is not None:
        if isinstance(node.obj, dict) and at_key in node.obj:
            instance = node.obj[at_key]
            assert isinstance(instance, instance_type)
            return instance
        node = node.parent

    return None


def find_mandatory_ctx_dict_instance(
        ctx: click.Context, at_key: str, instance_type: Type) -> Any:
    obj = find_ctx_dict_instance(ctx, at_key, instance_type)
    if obj is None:
        raise RuntimeError(
            "Cannot find any 'ctx.obj' of type 'dict' containing "
            f"an instance of type '{instance_type.__name__}' "
            f"at key '{at_key}'"
        )

    return obj


def mk_ctx_dict_pass_decorator(at_key: str, instance_type: Type):
    """Create a decorator similar to `click.make_pass_decorator` that will
        pass as an argument to decorated callback a context object stored
        in a `ctx.obj` of type `dict` at specified key and of specified
        type.

    This is an improvement over `click.make_pass_decorator`.
    """
    def decorator(f):
        def new_func(*args, **kwargs):
            ctx = click.get_current_context()
            obj = find_mandatory_ctx_dict_instance(ctx, at_key, instance_type)
            return ctx.invoke(f, obj, *args, **kwargs)
        return update_wrapper(new_func, f)
    return decorator
