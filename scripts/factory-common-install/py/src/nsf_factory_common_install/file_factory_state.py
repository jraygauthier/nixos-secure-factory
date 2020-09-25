from pathlib import Path

from .types_factory_state import FactoryState, FactoryStatePlainT, FactoryStateUser
from ._state_persistance_tools import (
    dump_plain_state_to_file,
    load_state_from_file_plain,
    StateFileError
)


class FactoryStateFileError(Exception):
    pass


class FactoryStateFileAccessError(FactoryStateFileError):
    pass


class FactoryStateFileFormatError(FactoryStateFileError):
    pass


def load_factory_state_from_file_plain(filename: Path) -> FactoryStatePlainT:
    try:
        return load_state_from_file_plain(filename)
    except StateFileError as e:
        raise FactoryStateFileAccessError(
            f"Cannot load factory state file: {str(e)}")


def parse_factory_state_user(in_d: FactoryStatePlainT) -> FactoryStateUser:
    try:
        user_d = in_d['user']
        return FactoryStateUser(
            id=user_d['id'],
            full_name=user_d['full-name'],
            email=user_d['email']
        )
    except KeyError as e:
        raise FactoryStateFileFormatError(
            f"Missing mandatory field: {str(e)}") from e


def parse_factory_state(in_d: FactoryStatePlainT) -> FactoryState:
    return FactoryState(
        user=parse_factory_state_user(in_d)
    )


def load_factory_state_from_file(
        filename: Path) -> FactoryState:
    fi_d = load_factory_state_from_file_plain(filename)
    return parse_factory_state(fi_d)


def load_factory_state_user_from_file(
        filename: Path) -> FactoryStateUser:
    fi_d = load_factory_state_from_file_plain(filename)
    return parse_factory_state_user(fi_d)


def dump_plain_factory_state_to_file(
        state: FactoryStatePlainT,
        out_filename: Path
) -> None:
    dump_plain_state_to_file(state, out_filename)


class FactoryStateFile:
    def __init__(self, filename: Path) -> None:
        self._filename = filename

    @property
    def filename(self) -> Path:
        return self._filename

    def load(self) -> FactoryState:
        return load_factory_state_from_file(self.filename)

    def load_plain(self) -> FactoryStatePlainT:
        return load_factory_state_from_file_plain(self.filename)

    def load_user(self) -> FactoryStateUser:
        return load_factory_state_user_from_file(
            self.filename)

    def load_field_user_id(self) -> str:
        # TODO: As this is a common operation, make this as fast and
        # robust as possible by only parsing the id field.
        return self.load_user().id

    def dump_plain(self, state: FactoryStatePlainT) -> None:
        return dump_plain_factory_state_to_file(
            state, self.filename)
