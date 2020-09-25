from pathlib import Path


class SshAuthRepo:
    """The workspace content repository.
    """
    def __init__(self, dir: Path):
        self._dir = dir

    @property
    def dir(self) -> Path:
        return self._dir


def mk_ssh_auth_repo(
        dir: Path
) -> SshAuthRepo:
    return SshAuthRepo(dir)
