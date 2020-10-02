from dataclasses import dataclass
from typing import Callable, Iterable, Any, Dict, Optional, List, Union
from functools import lru_cache
from itertools import chain
from ._ctx import CliCtxDbInterface

_FieldInT = List[str]
_FieldOutT = Union[None, str, List[str]]


class FieldValueInvalidError(Exception):
    pass


def _list_choices_default(db: CliCtxDbInterface) -> Iterable[str]:
    return []


def _sanitize_default(db: CliCtxDbInterface, value: _FieldInT) -> _FieldOutT:
    if not value:
        return None

    if 1 < len(value):
        raise FieldValueInvalidError(
            "Default value is of type optional 'str' but received a "
            f"'list' of lenght '{len(value)}' instead.")

    return value[0]


def _sanitize_default_list(db: CliCtxDbInterface, value: _FieldInT) -> _FieldOutT:
    return value


@dataclass
class FieldSchemaEntry:
    _list_choices: Callable[[CliCtxDbInterface], Iterable[Any]]
    _sanitize: Callable[[CliCtxDbInterface, _FieldInT], _FieldOutT]

    def list_choices(self, db: CliCtxDbInterface) -> Iterable[Any]:
        return self._list_choices(db)  # type: ignore

    def sanitize(self, db: CliCtxDbInterface, value: _FieldInT) -> _FieldOutT:
        return self._sanitize(db, value)  # type: ignore

    @classmethod
    def mk_default(cls) -> 'FieldSchemaEntry':
        return cls(
            _list_choices_default,
            _sanitize_default
        )


def _sanitize_state(db: CliCtxDbInterface, value: _FieldInT) -> _FieldOutT:
    return _sanitize_default_list(db, value)


def _list_state_choices(db: CliCtxDbInterface) -> Iterable[str]:
    return chain(_list_choices_default(db), db.list_device_states())


def _mk_field_shema_enter_default_list() -> FieldSchemaEntry:
    return FieldSchemaEntry(
        _list_choices_default,
        _sanitize_default_list
    )

@lru_cache(maxsize=1)
def _get_known_field_schema_d() -> Dict[str, Optional[FieldSchemaEntry]]:
    FSE = FieldSchemaEntry
    fse_def_list = _mk_field_shema_enter_default_list()

    # TODO: Consider preventing setting some read-only
    # fields.

    return {
        "identifier": None,
        "type": None,
        "backend": None,
        "hostname": None,
        "ssh-port": None,
        "uart-pty": None,
        "email": None,
        "gpg-id": None,
        "state": FSE(
            _list_state_choices,
            _sanitize_state
        ),
        "factory-installed-by": fse_def_list
    }


def get_field_schema(field_name: str) -> FieldSchemaEntry:
    fschema = _get_known_field_schema_d().get(field_name)
    if fschema is None:
        return FieldSchemaEntry.mk_default()

    return fschema


def list_known_field_names() -> Iterable[str]:
    return _get_known_field_schema_d().keys()
