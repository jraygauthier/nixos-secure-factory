from pathlib import Path
from typing import List, Optional

from .types_device_state import DeviceIdWType, DeviceState, DeviceStatePlainT
from ._state_persistance_tools import (
    dump_plain_state_to_file,
    format_plain_state_as_yaml_str,
    load_state_from_file_plain,
    StateFileError
)


class DeviceStateFileError(Exception):
    pass


class DeviceStateFileAccessError(DeviceStateFileError):
    pass


class DeviceStateFileFormatError(DeviceStateFileError):
    pass


def parse_device_state_field_id(in_d: DeviceStatePlainT) -> str:
    out = in_d['identifier']
    if not isinstance(out, str):
        raise DeviceStateFileFormatError(
            f"'id' field should be a string was instead: {type(out)}")
    return out


def parse_device_state_field_type(in_d: DeviceStatePlainT) -> str:
    out = in_d['type']
    if not isinstance(out, str):
        raise DeviceStateFileFormatError(
            f"'type' field should be a string was instead: {type(out)}")
    return out


def parse_device_state_fields_id_w_type(
        in_d: DeviceStatePlainT) -> DeviceIdWType:
    return DeviceIdWType(
        parse_device_state_field_id(in_d),
        parse_device_state_field_type(in_d)
    )


def parse_device_state_field_factory_installed_by(
        in_d: DeviceStatePlainT) -> Optional[List[str]]:
    out = in_d.get('factory-installed-by', None)
    for u in out:
        if not isinstance(u, str):
            raise DeviceStateFileFormatError(
                "'factory-installed-by' field should be a "
                "string was instead: {type(u)}")
    return out


def parse_device_state(in_d: DeviceStatePlainT) -> DeviceState:
    try:
        return DeviceState(
            id=parse_device_state_field_id(in_d),
            type=parse_device_state_field_type(in_d),
            hostname=in_d['hostname'],
            ssh_port=in_d['ssh-port'],
            gpg_id=in_d.get('gpg-id', None),
            factory_installed_by=in_d.get('factory-installed-by', None),
        )
    except KeyError as e:
        raise DeviceStateFileFormatError(
            f"Missing mandatory field: {str(e)}") from e


def load_device_state_from_file_plain(
        filename: Path) -> DeviceStatePlainT:
    try:
        return load_state_from_file_plain(filename)
    except StateFileError as e:
        raise DeviceStateFileAccessError(
            f"Cannot load device state file: {str(e)}")


def load_device_state_from_file(
        filename: Path) -> DeviceState:
    di_plain = load_device_state_from_file_plain(filename)
    return parse_device_state(di_plain)


def load_device_id_from_device_state_file(
        filename: Path) -> str:
    di_plain = load_device_state_from_file_plain(filename)
    return parse_device_state_field_id(di_plain)


def load_device_type_from_device_state_file(
        filename: Path) -> str:
    di_plain = load_device_state_from_file_plain(filename)
    return parse_device_state_field_type(di_plain)


def load_device_id_w_type_from_device_state_file(
        filename: Path) -> DeviceIdWType:
    di_plain = load_device_state_from_file_plain(filename)
    return parse_device_state_fields_id_w_type(di_plain)


def dump_plain_device_state_to_file(
        state: DeviceStatePlainT,
        out_filename: Path
) -> None:
    return dump_plain_state_to_file(state, out_filename)


def format_plain_device_state_as_yaml_str(
        state: DeviceStatePlainT) -> str:
    return format_plain_state_as_yaml_str(state)


class DeviceStateFile:
    def __init__(self, filename: Path) -> None:
        self._filename = filename

    @property
    def filename(self) -> Path:
        return self._filename

    def load(self) -> DeviceState:
        return load_device_state_from_file(self.filename)

    def load_plain(self) -> DeviceStatePlainT:
        return load_device_state_from_file_plain(self.filename)

    def load_field_id(self) -> str:
        return load_device_id_from_device_state_file(
            self.filename)

    def load_field_type(self) -> str:
        return load_device_type_from_device_state_file(
            self.filename)

    def dump_plain(self, state: DeviceStatePlainT) -> None:
        return dump_plain_device_state_to_file(
            state, self.filename)
