import click
import logging


@click.group()
def member() -> None:
    """Ssh group member related commands."""
    pass


@member.command()  # noqa F811
def add() -> None:
    """Add a *ssh user* to a *ssh group*."""
    logging.info("group member add")


@member.command()  # noqa F811
def rm() -> None:
    """Remove a *ssh user* from a *ssh group*."""
    logging.info("group member rm")


@member.command()  # noqa F811
def ls() -> None:
    """List members for specified *ssh group*."""
    logging.info("group member ls")
