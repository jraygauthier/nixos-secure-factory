import click
import logging

LOGGER = logging.getLogger(__name__)


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
def cli() -> None:
    """Ssh authorization tool for nixos-secure-factory.

    All commands operate on the current *ssh auth dir* which
    by default correspond to the *current working directory*.
    """
    setup_verbose(1)


@cli.command()
def info() -> None:
    """Print information about the current *ssh auth dir*."""
    LOGGER.info("info")


@cli.group()
def git() -> None:
    """Run various `git` commands on the current *ssh auth dir*."""
    pass


@git.command()
def status() -> None:
    """Run `git` status for the current *ssh auth dir*."""
    LOGGER.info("git status")


@git.command()
def diff() -> None:
    """Run `git` diff for the current *ssh auth dir*."""
    LOGGER.info("git diff")


@cli.group()
def user() -> None:
    """Ssh users related commands."""
    pass


@user.command()
def add() -> None:
    """Add a new *ssh user*."""
    LOGGER.info("user add")


@user.command()
def rm() -> None:
    """Remove an existing *ssh user*."""
    LOGGER.info("user rm")


@user.command()
def ls() -> None:
    """List existing *ssh user*."""
    LOGGER.info("user ls")


@user.command()
def authorize() -> None:
    """Authorize a single *ssh user* to *device user(s)*."""
    LOGGER.info("user authorize")


@user.command()
def deauthorize() -> None:
    """De-authorize a single *ssh user* from *device user(s)*."""
    LOGGER.info("user deauthorize")


@user.group()
def pubkey() -> None:
    """Ssh user public key related commands."""
    pass


@pubkey.command()
def set() -> None:
    """Set a new *ssh public key* for the specified user."""
    LOGGER.info("user pubkey set")


@pubkey.command()
def print() -> None:
    """Print current *ssh public key* for the specified user."""
    LOGGER.info("user pubkey print")


@cli.group()
def group() -> None:
    """Ssh groups related commands."""
    pass


@group.command()  # noqa F811
def add() -> None:
    """Add a new *ssh group*."""
    LOGGER.info("group add")


@group.command()  # noqa F811
def rm() -> None:
    """Remove and existing *ssh group*."""
    LOGGER.info("group rm")


@group.command()  # noqa F811
def ls() -> None:
    """List existing *ssh group*."""
    LOGGER.info("group ls")


@group.command()  # noqa F811
def authorize() -> None:
    """Authorize a *ssh group* to *device user(s)*."""
    LOGGER.info("group authorize")


@group.command()  # noqa F811
def deauthorize() -> None:
    """De-authorize a *ssh group* from *device user(s)*."""
    LOGGER.info("group deauthorize")


@group.group()
def member() -> None:
    """Ssh group member related commands."""
    pass


@member.command()  # noqa F811
def add() -> None:
    """Add a *ssh user* to a *ssh group*."""
    LOGGER.info("group member add")


@member.command()  # noqa F811
def rm() -> None:
    """Remove a *ssh user* from a *ssh group*."""
    LOGGER.info("group member rm")


@member.command()  # noqa F811
def ls() -> None:
    """List members for specified *ssh group*."""
    LOGGER.info("group member ls")


if __name__ == "__main__":
    cli()
