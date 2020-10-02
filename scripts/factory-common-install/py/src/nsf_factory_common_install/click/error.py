"""A couple of click helpers.

These allow us to standardize how we output messages and errors
throughout the various nsf cli application.

Some of these also allow us to standardize some commonly used
patterns.
"""
import click


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


def echo_error(msg: str) -> None:
    click.echo(f"Error: {_format_error_msg(msg)}", err=True)


def echo_warning(msg: str) -> None:
    click.echo(f"Warning: {_format_warning_msg(msg)}", err=True)
