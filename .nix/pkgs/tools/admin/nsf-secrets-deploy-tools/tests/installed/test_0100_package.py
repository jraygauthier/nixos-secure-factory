from pathlib import Path
from nsft_shell_utils.program import call_shell_program

from test_lib.env import (
    are_package_propagated_dependencies_installed,
    is_package_installed,
)


def test_package_installed():
    assert is_package_installed()


def test_propagated_dependencies_installed():
    assert are_package_propagated_dependencies_installed()


def test_get_sh_lib_dir():
    lines = call_shell_program("pkg-nsf-secrets-deploy-tools-get-sh-lib-dir")
    assert lines
    dir_path = Path(lines[0])
    assert dir_path.exists()

    gpg_file_deploy_sh_module_path = dir_path.joinpath("pgp-file-deploy.sh")
    assert gpg_file_deploy_sh_module_path.exists()

    gpgnupg_deploy_sh_module_path = dir_path.joinpath("pgp-gnupg-keyring-deploy.sh")
    assert gpgnupg_deploy_sh_module_path.exists()
