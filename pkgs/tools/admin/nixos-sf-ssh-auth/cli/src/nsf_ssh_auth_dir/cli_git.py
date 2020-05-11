import click
import logging


@click.group()
def git() -> None:
    """Run various `git` commands on the current *ssh auth dir*."""
    pass


@git.command()
def status() -> None:
    """Run `git` status for the current *ssh auth dir*."""
    logging.info("git status")


@git.command()
def diff() -> None:
    """Run `git` diff for the current *ssh auth dir*."""
    logging.info("git diff")
