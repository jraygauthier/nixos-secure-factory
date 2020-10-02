from abc import ABC
from typing import Any, Callable, Dict, Optional

import click

from nsf_factory_common_install.click.ctx_dict import (
    find_mandatory_ctx_dict_instance,
    mk_ctx_dict_obj,
)


class CliCtxDbBase(ABC):
    KEY = "nsf_factory_intsall_cli_db"
    MkFnT = Callable[[click.Context], 'CliCtxDbBase']


class _CliCtxLazyDb:
    def __init__(self, mk_db: CliCtxDbBase.MkFnT) -> None:
        self._mk_db = mk_db
        self._db = None

    def __call__(self, ctx: click.Context) -> CliCtxDbBase:
        if self._db is not None:
            return self._db

        instance = self._mk_db(ctx)
        return instance


def mk_cli_db_obj_d(
        mk_db: CliCtxDbBase.MkFnT, db_key: Optional[str] = None
) -> Dict[str, Any]:
    if db_key is None:
        db_key = CliCtxDbBase.KEY

    return mk_ctx_dict_obj({
        db_key: _CliCtxLazyDb(mk_db)
    })


def get_cli_ctx_db_base(
        ctx: click.Context, db_key: Optional[str] = None
) -> CliCtxDbBase:
    if db_key is None:
        db_key = CliCtxDbBase.KEY

    lazy_db = find_mandatory_ctx_dict_instance(ctx, db_key, _CliCtxLazyDb)
    return lazy_db(ctx)
