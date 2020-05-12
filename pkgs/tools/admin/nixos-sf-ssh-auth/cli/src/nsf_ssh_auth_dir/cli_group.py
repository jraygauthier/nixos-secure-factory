import click
import logging

from .cli_group_member import member


@click.group()
def group() -> None:
    """Ssh groups related commands."""
    pass


@group.command()
def add() -> None:
    """Add a new *ssh group*."""
    logging.info("group add")


@group.command()
def rm() -> None:
    """Remove and existing *ssh group*."""
    logging.info("group rm")


@group.command()
def ls() -> None:
    """List existing *ssh group*."""
    logging.info("group ls")


@group.command()
def authorize() -> None:
    """Authorize a *ssh group* to *device user(s)*."""
    logging.info("group authorize")


@group.command()
def deauthorize() -> None:
    """De-authorize a *ssh group* from *device user(s)*."""
    logging.info("group deauthorize")


group.add_command(member)
