from dataclasses import dataclass
from typing import Callable, Iterable, Any, Dict, Optional
from functools import lru_cache
from itertools import chain
from ._ctx import CliCtxDbInterface

NULL_STR = "null"


def _list_choices_default(db: CliCtxDbInterface) -> Iterable[str]:
    return [NULL_STR]


def _sanitize_default(db: CliCtxDbInterface, value: str) -> Optional[str]:
    if NULL_STR == value:
        return None
    return value


@dataclass
class FieldSchemaEntry:
    _list_choices: Callable[[CliCtxDbInterface], Iterable[Any]]
    _sanitize: Callable[[CliCtxDbInterface, str], Any]

    def list_choices(self, db: CliCtxDbInterface) -> Iterable[Any]:
        return self._list_choices(db)  # type: ignore

    def sanitize(self, db: CliCtxDbInterface, value: str) -> Any:
        return self._sanitize(db, value)  # type: ignore

    @classmethod
    def mk_default(cls) -> 'FieldSchemaEntry':
        return cls(
            _list_choices_default,
            _sanitize_default
        )


def _sanitize_state(db: CliCtxDbInterface, value: str) -> Optional[str]:
    return _sanitize_default(db, value)


def _list_state_choices(db: CliCtxDbInterface) -> Iterable[str]:
    return chain(_list_choices_default(db), db.list_device_states())


@lru_cache(maxsize=1)
def _get_known_field_schema_d() -> Dict[str, Optional[FieldSchemaEntry]]:
    FSE = FieldSchemaEntry

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
        )
    }


def get_field_schema(field_name: str) -> FieldSchemaEntry:
    fschema = _get_known_field_schema_d().get(field_name)
    if fschema is None:
        return FieldSchemaEntry.mk_default()

    return fschema


def list_known_field_names() -> Iterable[str]:
    return _get_known_field_schema_d().keys()
