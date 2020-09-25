import click
from abc import ABC, abstractmethod
from typing import Iterable, Dict, Any, Callable

from ..types_device import DeviceInstanceWIdWTypeWStateWStateFile
from .click import find_mandatory_ctx_dict_instance


CliCtxDbDeviceInstance = DeviceInstanceWIdWTypeWStateWStateFile


class CliCtxDbBase(ABC):
    KEY = "nsf_factory_intsall_cli_db"
    MkFnT = Callable[[click.Context], 'CliCtxDbBase']


class CliCtxDbWDeviceList(CliCtxDbBase):
    @abstractmethod
    def list_device_instances(self) -> Iterable[CliCtxDbDeviceInstance]:
        pass


class _CliCtxLazyDb:
    def __init__(self, mk_db: CliCtxDbBase.MkFnT) -> None:
        self._mk_db = mk_db
        self._db = None

    def __call__(self, ctx: click.Context) -> CliCtxDbBase:
        if self._db is not None:
            return self._db

        instance = self._mk_db(ctx)
        return instance


def mk_cli_db_obj_d(mk_db: CliCtxDbBase.MkFnT) -> Dict[str, Any]:
    return {
        CliCtxDbBase.KEY: _CliCtxLazyDb(mk_db)
    }


def get_cli_ctx_db_base(ctx: click.Context) -> CliCtxDbBase:
    assert isinstance(ctx.obj, dict), (
        "Expected 'obj' of 'dict' type. "
        f"Found instead: '{type(ctx.obj).__name__}'."
    )

    key = CliCtxDbBase.KEY
    instance_type = _CliCtxLazyDb

    lazy_db = find_mandatory_ctx_dict_instance(ctx, key, instance_type)
    assert isinstance(lazy_db, instance_type), (
        f"Expected instance of type '{instance_type}' at key '{key}'. "
        f"Found instead: '{type(lazy_db).__name__}'."
    )

    return lazy_db(ctx)


def get_cli_ctx_db_w_device_list(ctx: click.Context) -> CliCtxDbWDeviceList:
    out = get_cli_ctx_db_base(ctx)
    assert isinstance(out, CliCtxDbWDeviceList)
    return out
