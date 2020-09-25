def run_cli_device_common_ssh_auth() -> None:
    from .device_common_ssh_auth_dir import run_cli
    run_cli()


def run_cli_device_ssh_auth() -> None:
    from .device_ssh_auth_dir import run_cli
    run_cli()


def run_cli_device_state() -> None:
    from .device_state import run_cli
    run_cli()


def run_cli_device_current_state() -> None:
    from .device_current_state import run_cli
    run_cli()
