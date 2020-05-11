import click
import logging


@click.group()
def pubkey() -> None:
    """Ssh user public key related commands."""
    pass


@pubkey.command()
def set() -> None:
    """Set a new *ssh public key* for the specified user."""
    logging.info("user pubkey set")


@pubkey.command()
def print() -> None:
    """Print current *ssh public key* for the specified user."""
    logging.info("user pubkey print")
