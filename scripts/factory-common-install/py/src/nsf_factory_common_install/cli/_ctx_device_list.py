from abc import abstractmethod
from typing import Iterable

import click

from ..types_device import DeviceInstanceWIdWTypeWStateWStateFile
from ._ctx import CliCtxDbBase, get_cli_ctx_db_base

CliCtxDbDeviceInstance = DeviceInstanceWIdWTypeWStateWStateFile


class CliCtxDbWDeviceList(CliCtxDbBase):
    @abstractmethod
    def list_device_instances(self) -> Iterable[CliCtxDbDeviceInstance]:
        pass


def get_cli_ctx_db_w_device_list(ctx: click.Context) -> CliCtxDbWDeviceList:
    out = get_cli_ctx_db_base(ctx)
    assert isinstance(out, CliCtxDbWDeviceList)
    return out
