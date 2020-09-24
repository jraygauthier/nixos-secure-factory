import json
import yaml
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, List, Dict, Any, NamedTuple


DeviceInfoPlainT = Dict[str, Any]


class DeviceIdWType(NamedTuple):
    id: str
    type: str


@dataclass
class DeviceInfo:
    id: str
    type: str
    hostname: str
    ssh_port: str
    gpg_id: Optional[str]
    factory_installed_by: Optional[List[str]]


def parse_device_info_field_id(in_d: DeviceInfoPlainT) -> str:
    out = in_d['identifier']
    assert isinstance(out, str)
    return out


def parse_device_info_field_type(in_d: DeviceInfoPlainT) -> str:
    out = in_d['type']
    assert isinstance(out, str)
    return out


def parse_device_info_fields_id_w_type(
        in_d: DeviceInfoPlainT) -> DeviceIdWType:
    return DeviceIdWType(
        parse_device_info_field_id(in_d),
        parse_device_info_field_type(in_d)
    )


def parse_device_info_field_factory_installed_by(
        in_d: DeviceInfoPlainT) -> Optional[List[str]]:
    out = in_d.get('factory-installed-by', None)
    for u in out:
        assert isinstance(u, str)
    return out


def parse_device_info(in_d: DeviceInfoPlainT) -> DeviceInfo:
    return DeviceInfo(
        id=parse_device_info_field_id(in_d),
        type=parse_device_info_field_type(in_d),
        hostname=in_d['hostname'],
        ssh_port=in_d['ssh-port'],
        gpg_id=in_d.get('gpg-id', None),
        factory_installed_by=in_d.get('factory-installed-by', None),
    )


def _load_device_info_from_json_file_plain(
        filename: Path) -> DeviceInfoPlainT:
    with open(filename) as f:
        # We want to preserve key order. Json already does that.
        out = json.load(f)

    assert out is not None
    return out


def _load_device_info_from_yaml_file_plain(
        filename: Path) -> DeviceInfoPlainT:
    with open(filename) as f:
        # We want to preserve key order.
        # Yaml already does that on load.
        out = yaml.safe_load(f)

    assert out is not None
    return out


def load_device_info_from_file_plain(
        filename: Path) -> DeviceInfoPlainT:
    if ".yaml" == filename.suffix:
        return _load_device_info_from_yaml_file_plain(filename)

    assert ".json" == filename.suffix
    return _load_device_info_from_json_file_plain(filename)


def load_device_info_from_file(
        filename: Path) -> DeviceInfo:
    di_plain = load_device_info_from_file_plain(filename)
    return parse_device_info(di_plain)


def load_device_id_from_device_info_file(
        filename: Path) -> str:
    di_plain = load_device_info_from_file_plain(filename)
    return parse_device_info_field_id(di_plain)


def load_device_type_from_device_info_file(
        filename: Path) -> str:
    di_plain = load_device_info_from_file_plain(filename)
    return parse_device_info_field_type(di_plain)


def load_device_id_w_type_from_device_info(
        filename: Path) -> DeviceIdWType:
    di_plain = load_device_info_from_file_plain(filename)
    return parse_device_info_fields_id_w_type(di_plain)
