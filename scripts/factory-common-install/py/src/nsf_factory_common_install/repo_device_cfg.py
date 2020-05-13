from dataclasses import dataclass
from typing import Optional
from pathlib import Path

from .workspace_paths import get_device_cfg_repo_root_dir_path
from .file_device_info import load_device_type_from_device_info_yaml_file


@dataclass
class DeviceCfgRepoInstanceDirLayout:
    info_file_stem: str
    info_file_ext: str
    ssh_auth_dir_name: str


@dataclass
class DeviceCfgRepoLayout:
    instance_dir: DeviceCfgRepoInstanceDirLayout
    instance_set_dir_name: str
    type_set_dir_name: str
    family_set_dir_name: str
    update_dir_name: str
    ssh_auth_dir_name: str


def mk_default_device_cfg_repo_layout() -> DeviceCfgRepoLayout:
    return DeviceCfgRepoLayout(
        instance_dir=DeviceCfgRepoInstanceDirLayout(
            info_file_stem="device",
            info_file_ext="json",
            ssh_auth_dir_name="ssh"
        ),
        instance_set_dir_name="device",
        type_set_dir_name="device-type",
        family_set_dir_name="device-family",
        update_dir_name="device-update",
        ssh_auth_dir_name="device-ssh"
    )


def ensure_device_cfg_repo_layout_or_default(
        layout: Optional[DeviceCfgRepoLayout]) -> DeviceCfgRepoLayout:
    if layout is not None:
        return layout

    return mk_default_device_cfg_repo_layout()


class DeviceCfgRepoInstancePaths:
    def __init__(
            self, instance_dir: Path, layout: DeviceCfgRepoInstanceDirLayout
    ) -> None:
        self._instance_dir = instance_dir
        self._layout = layout

    @property
    def info(self) -> Path:
        return self._instance_dir.joinpath(
            self._layout.info_file_stem).with_suffix(
                self._layout.info_file_ext)


@dataclass
class DeviceInstanceInfo:
    id: str
    type: str


class DeviceCfgRepoPaths:
    def __init__(
            self,
            root_dir: Path,
            layout: DeviceCfgRepoLayout
    ) -> None:
        self._root_dir = root_dir
        self._layout = layout

    @property
    def instance_set_dir(self) -> Path:
        return self._root_dir.joinpath(self._layout.instance_set_dir_name)

    def for_instance_dir(self, device_id: str) -> DeviceCfgRepoInstancePaths:
        instance_dir = self.instance_set_dir.joinpath(device_id)
        return DeviceCfgRepoInstancePaths(instance_dir, self._layout.instance_dir)

    @property
    def type_set_dir(self) -> Path:
        return self._root_dir.joinpath(self._layout.type_set_dir_name)

    @property
    def family_set_dir(self) -> Path:
        return self._root_dir.joinpath(self._layout.family_set_dir_name)

    @property
    def ssh_auth_dir(self) -> Path:
        return self._root_dir.joinpath(self._layout.ssh_auth_dir_name)


class DeviceCfgRepoPathsExt(DeviceCfgRepoPaths):
    def __init__(
            self,
            root_dir: Path,
            layout: DeviceCfgRepoLayout,
            instance_info: DeviceInstanceInfo
    ) -> None:
        super().__init__(root_dir, layout)
        self._instance_info = instance_info

    @property
    def instance_dir(self) -> DeviceCfgRepoInstancePaths:
        return self.for_instance_dir(self._instance_info.id)


def get_device_cfg_paths(
        root_dir: Optional[Path] = None,
        layout: Optional[DeviceCfgRepoLayout] = None
) -> DeviceCfgRepoPaths:
    if root_dir is None:
        root_dir = get_device_cfg_repo_root_dir_path()
    layout = ensure_device_cfg_repo_layout_or_default(layout)
    return DeviceCfgRepoPaths(root_dir, layout)


def get_device_cfg_paths_ext(
        device_id: str,
        device_type: Optional[str],
        root_dir: Optional[Path] = None,
        layout: Optional[DeviceCfgRepoLayout] = None
) -> DeviceCfgRepoPathsExt:
    if root_dir is None:
        root_dir = get_device_cfg_repo_root_dir_path()
    layout = ensure_device_cfg_repo_layout_or_default(layout)

    if device_type is None:
        device_info_filename = root_dir.joinpath(
            layout.instance_set_dir_name).joinpath(
                layout.instance_dir.info_file_stem).with_suffix(
                    layout.instance_dir.info_file_ext)

        device_type = load_device_type_from_device_info_yaml_file(
            device_info_filename)

    instance_info = DeviceInstanceInfo(device_id, device_type)
    return DeviceCfgRepoPathsExt(root_dir, layout, instance_info)
