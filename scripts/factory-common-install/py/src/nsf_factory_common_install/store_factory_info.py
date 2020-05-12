import yaml
from pathlib import Path
from typing import Any, Dict
from dataclasses import dataclass

from .workspace_paths import (
    get_nsf_workspace_dir_path,
)


@dataclass
class FactoryInfoUser:
    id: str
    full_name: str
    email: str


@dataclass
class FactoryInfo:
    user: FactoryInfoUser


def get_factory_info_store_yaml_filename() -> Path:
    device_cfg_repo_root_dir = get_nsf_workspace_dir_path()
    return device_cfg_repo_root_dir.joinpath(".factory-info.yaml")


def load_factory_info_from_store_plain() -> Dict[str, Any]:
    yaml_store_path = get_factory_info_store_yaml_filename()
    with open(yaml_store_path) as f:
        # We want to preserve key order.
        # Yaml already does that on load.
        out = yaml.safe_load(f)

    assert out is not None
    return out


def parse_factory_info_user(in_d: Dict[str, Any]) -> FactoryInfoUser:
    user_d = in_d['user']
    return FactoryInfoUser(
        id=user_d['id'],
        full_name=user_d['full-name'],
        email=user_d['email']
    )


def parse_factory_info(in_d: Dict[str, Any]) -> FactoryInfo:
    return FactoryInfo(
        user=parse_factory_info_user(in_d)
    )


def load_factory_info_from_store() -> FactoryInfo:
    fi_d = load_factory_info_from_store_plain()
    return parse_factory_info(fi_d)


def load_factory_info_user_from_store() -> FactoryInfoUser:
    fi_d = load_factory_info_from_store_plain()
    return parse_factory_info_user(fi_d)


def get_factory_info_user_id() -> str:
    return load_factory_info_user_from_store().id
