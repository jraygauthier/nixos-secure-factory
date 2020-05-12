import json
import yaml
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, List, Dict, Any


DeviceInfoPlainT = Dict[str, Any]


@dataclass
class DeviceInfo:
    id: str
    type: str
    hostname: str
    ssh_port: str
    gpg_id: Optional[str]
    factory_installed_by: Optional[List[str]]


def parse_device_info_id(in_d: DeviceInfoPlainT) -> str:
    out = in_d['identifier']
    assert isinstance(out, str)
    return out


def parse_device_info_factory_installed_by(
        in_d: DeviceInfoPlainT) -> Optional[List[str]]:
    out = in_d.get('factory-installed-by', None)
    for u in out:
        assert isinstance(u, str)
    return out


def parse_device_info(in_d: DeviceInfoPlainT) -> DeviceInfo:
    return DeviceInfo(
        id=parse_device_info_id(in_d),
        type=in_d['type'],
        hostname=in_d['hostname'],
        ssh_port=in_d['ssh-port'],
        gpg_id=in_d.get('gpg-id', None),
        factory_installed_by=in_d.get('factory-installed-by', None),
    )


def load_device_info_from_json_file_plain(
        filename: Path) -> DeviceInfoPlainT:
    with open(filename) as f:
        # We want to preserve key order. Json already does that.
        out = json.load(f)

    assert out is not None
    return out


def load_device_info_from_json_file(
        filename: Path) -> DeviceInfo:
    di_plain = load_device_info_from_json_file_plain(filename)
    return parse_device_info(di_plain)


def load_device_info_from_yaml_file_plain(
        filename: Path) -> DeviceInfoPlainT:
    with open(filename) as f:
        # We want to preserve key order.
        # Yaml already does that on load.
        out = yaml.safe_load(f)

    assert out is not None
    return out


def load_device_info_from_yaml_file(
        filename: Path) -> DeviceInfo:
    di_plain = load_device_info_from_yaml_file_plain(filename)
    return parse_device_info(di_plain)


def load_device_id_from_device_info_yaml_file(
        filename: Path) -> str:
    di_plain = load_device_info_from_yaml_file_plain(filename)
    return parse_device_info_id(di_plain)
