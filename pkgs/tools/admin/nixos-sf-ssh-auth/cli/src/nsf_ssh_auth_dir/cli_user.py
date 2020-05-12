import click
import logging

from .cli_user_pubkey import pubkey


@click.group()
def user() -> None:
    """Ssh users related commands."""
    pass


@user.command()
def add() -> None:
    """Add a new *ssh user*."""
    logging.info("user add")


@user.command()
def rm() -> None:
    """Remove an existing *ssh user*."""
    logging.info("user rm")


@user.command()
def ls() -> None:
    """List existing *ssh user*."""
    logging.info("user ls")


@user.command()
def authorize() -> None:
    """Authorize a single *ssh user* to *device user(s)*."""
    logging.info("user authorize")


@user.command()
def deauthorize() -> None:
    """De-authorize a single *ssh user* from *device user(s)*."""
    logging.info("user deauthorize")


user.add_command(pubkey)
