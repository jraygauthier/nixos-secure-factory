from abc import abstractmethod
from dataclasses import dataclass
from typing import Any, Dict, Iterable, Optional

import click

from nsf_factory_common_install.file_device_state import DeviceStateFile
from nsf_factory_common_install.repo_device_cfg import (
    DeviceCfgRepo,
    DeviceCfgRepoInstance,
)

from ..click import mk_ctx_dict_pass_decorator
from .._ctx import (
    CliCtxDbBase,
    CliCtxDbWDeviceList,
    CliCtxDbDeviceInstance,
    get_cli_ctx_db_base,
    mk_cli_db_obj_d,
)


class CliCtxDbInterface(
        CliCtxDbWDeviceList
):
    """The cli context occuring before anything is known / set.

    Mainly used by autocompletion callbacks and potentially
    options callbacks if any.

    This was required in order to parameterize the autocompletion logic.

    This should be provided as initial `obj` through the top level group's
    `context_settings`.

    See below `mk_cli_context_settings`.
    """
    @abstractmethod
    def get_current_device(
            self) -> Optional[CliCtxDbDeviceInstance]:
        pass

    @abstractmethod
    def get_device_instance(
            self, device_id: str) -> CliCtxDbDeviceInstance:
        pass

    @abstractmethod
    def list_device_states(self) -> Iterable[str]:
        pass


def mk_cli_context_settings(
    mk_db: CliCtxDbBase.MkFnT,
) -> Dict[str, Any]:
    """Create initial click context parameters for this cli application.

    This is currently used as input for autocompletion.

    Example:
        `@click.group(context_settings=mk_cli_context_settings())`

    See `init_cli_ctx` which depends on this.
    """

    obj_d = mk_cli_db_obj_d(mk_db)

    return dict(
        obj=obj_d,
        # It it also possible to customize cli default values from here.
        # <https://click.palletsprojects.com/en/7.x/commands/#overriding-defaults>
        # default_map
    )


def get_cli_ctx_db(ctx: click.Context) -> CliCtxDbInterface:
    out = get_cli_ctx_db_base(ctx)
    assert isinstance(out, CliCtxDbInterface)
    return out


@dataclass
class CliCtx:
    KEY = "device_state"

    db: CliCtxDbInterface

    # The resolved device instance.
    device: DeviceCfgRepoInstance

    # The state file stored in the configuration repository.
    rw_target_file: DeviceStateFile

    # The device id when explicitely specified via the
    # top level option or environement variable.
    explicit_device_id: Optional[str]

    checkout_device_repo: Optional[DeviceCfgRepo]

    # The state file checkout location if any.
    checkout_target_file: Optional[DeviceStateFile]


def init_cli_ctx(
        ctx: click.Context,
        device: DeviceCfgRepoInstance,
        rw_target_file: DeviceStateFile,
        explicit_device_id: Optional[str] = None,
        checkout_device_repo: Optional[DeviceCfgRepo] = None,
        checkout_target_file: Optional[DeviceStateFile] = None
) -> CliCtx:
    """Initialize this cli application's context.

    Args:
        ctx: The click context.

    Returns:
        The actual initial context value.
    """
    # Make sure the provided context db was of the proper type.
    ctx_db = get_cli_ctx_db(ctx)
    assert isinstance(ctx_db, CliCtxDbInterface)

    init_ctx = CliCtx(
        ctx_db,
        device,
        rw_target_file,
        explicit_device_id,
        checkout_device_repo,
        checkout_target_file
    )

    assert isinstance(ctx.obj, dict), (
        f"Found instead: '{type(ctx.obj).__name__}'.")

    ctx.obj[CliCtx.KEY] = init_ctx
    return init_ctx


pass_cli_ctx = mk_ctx_dict_pass_decorator(CliCtx.KEY, CliCtx)
