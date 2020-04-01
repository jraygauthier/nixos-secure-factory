import logging

from pathlib import Path

from nsft_shell_utils.module import call_sh_module_fn

from test_lib.env import are_package_propagated_dependencies_installed

LOGGER = logging.getLogger(__name__)


def _get_shlib_dir() -> Path:
    return Path(__file__).parent.joinpath(
        "../../sh-lib").resolve()


def _get_pgp_file_deploy_sh_module() -> Path:
    return _get_shlib_dir().joinpath("pgp-file-deploy.sh")


def _call_pgp_file_deploy_sh_module_fn(fn_name: str, *args, **kwargs) -> None:
    call_sh_module_fn(_get_pgp_file_deploy_sh_module(), fn_name, *args, **kwargs)


def _get_gnupg_deploy_sh_module() -> Path:
    return _get_shlib_dir().joinpath("pgp-gnupg-keyring-deploy.sh")


def _call_gnupg_deploy_sh_module_fn(fn_name: str, *args, **kwargs) -> None:
    call_sh_module_fn(_get_gnupg_deploy_sh_module(), fn_name, *args, **kwargs)


def test_propagated_dependencies_installed():
    assert are_package_propagated_dependencies_installed()


def test_modules_sourced() -> None:
    _call_pgp_file_deploy_sh_module_fn("true")
    _call_gnupg_deploy_sh_module_fn("true")
