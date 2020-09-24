"""Device configuration repository well known locations / layout.

Provide some helper to quickly obtain meaningful information about a device
configuration repo's important locations given a custom or default layout and
optionally the description of a particular device instance.

TODO: Move the following to some top level markdown doc page and replace
by a reference to it.

Some concepts:

 -  *device config repository*:

    The repository or directory that contain the nix/nixos files
    required to configure any of the managed devices.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/`

 -  *device instance*:

    A particular device.

    A *device instance* **must** be of a particular *device type*.

    A nixos configuration for a particular *device instance* is generated
    at the time of building the nixos closure for the instance and
    merely customizes the nixos configuration for its *device type* using
    the information provided via its *device info file*.

 -  *device instance directory*:

    The directory that contain information about a specific device.

    Usually found at `[repo]/device/[my-device-name]/`.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device/demo-virtual-box-vm/`.

 -  *device info file*:

    The file that uniquely describe a device / its identity / memberships /
    parameters.

    This holds the differentiating information between various devices of
    the same type.

    Currently a `*.json` file by default located at
    `[repo]/device/[my-device-id]/device.json`.

    What is nice in have a `*.json` file instead of a nix file for a *device instance*
    parameterization is that it is possible and easy to create tools to automate the
    manipulation of these files (as opposed to `*.nix` files).

 -  *device type*:

    The type of a particular device. Devices of the same
    type will usually share a common nixos configuration parameterized by the
    *device info file*.

    A *device type* can *optionally* belong to a *type family*

 -  *device type directory*

    The directory where the nixos configuration for a device usually starts.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device-type/virtual-box-vm/`.

 -  *device family*:

    The type of the device type if any.

    This allows to share some configurations between types.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device-family/generic/`.

TODO:

 -  This should pave the way for the eventuallity of an optional repo layout
    configuration file, potentially found at the root of the repository.
"""
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .file_device_info import (
    DeviceIdWType,
    load_device_type_from_device_info_file,
)
from .workspace_paths import get_device_cfg_repo_root_dir_path


@dataclass
class DeviceCfgRepoInstanceDirLayout:
    """The layout of the per device directory.

    The layout of a *device instance directory* usually found at
    `[repo]/device/[my-device-name]/`.

    See module docstring for definition of the concept and examples.
    """
    info_file_stem: str
    info_file_ext: str
    ssh_auth_dir_name: str

    @classmethod
    def mk_default(cls) -> 'DeviceCfgRepoInstanceDirLayout':
        return cls(
            info_file_stem="device",
            info_file_ext="json",
            ssh_auth_dir_name="ssh"
        )


@dataclass
class DeviceCfgRepoLayout:
    """The layout of a device config repository.

    This allows one to describe how the repository is
    structured, potentially diverging from the default
    layout.
    """
    instance_dir: DeviceCfgRepoInstanceDirLayout
    instance_set_dir_name: str
    type_set_dir_name: str
    family_set_dir_name: str
    update_dir_name: str
    ssh_auth_dir_name: str

    @classmethod
    def mk_default(cls) -> 'DeviceCfgRepoLayout':
        """The default device config repo layout the will
            be used if none provided.

        """
        return cls(
            instance_dir=DeviceCfgRepoInstanceDirLayout.mk_default(),
            instance_set_dir_name="device",
            type_set_dir_name="device-type",
            family_set_dir_name="device-family",
            update_dir_name="device-update",
            ssh_auth_dir_name="device-ssh"
        )


def ensure_device_cfg_repo_layout_or_default(
        layout: Optional[DeviceCfgRepoLayout]) -> DeviceCfgRepoLayout:
    """Given a optional layout instance, make sure that
        if `None`, the default is returned.
    """
    if layout is not None:
        return layout

    return DeviceCfgRepoLayout.mk_default()


class DeviceCfgRepoInstancePaths:
    """Paths to various well known locations inside a device
        instance directory.

    A device instance directory is usually found at
    `[repo]/device/[my-device-id]/`.
    """
    def __init__(
            self, instance_dir: Path, layout: DeviceCfgRepoInstanceDirLayout
    ) -> None:
        self._instance_dir = instance_dir
        self._layout = layout

    @property
    def info_file(self) -> Path:
        """Path to the *device info file* / device instance's info file.
        Usually found at `[my-device-instance-dir]/device.json`.
        """
        return self._instance_dir.joinpath(
            self._layout.info_file_stem).with_suffix(
                self._layout.info_file_ext)


class DeviceCfgRepoPaths:
    """Paths to various well known locations of a device
        configuration repository.
    """
    def __init__(
            self,
            root_dir: Path,
            layout: DeviceCfgRepoLayout
    ) -> None:
        self._root_dir = root_dir
        self._layout = layout

    @property
    def instance_set_dir(self) -> Path:
        """Return the path where are located the various
            *device instance directories*.
        """
        return self._root_dir.joinpath(self._layout.instance_set_dir_name)

    @property
    def type_set_dir(self) -> Path:
        """Return the path where are located the various
            *device type directories*.
        """
        return self._root_dir.joinpath(self._layout.type_set_dir_name)

    @property
    def family_set_dir(self) -> Path:
        """Return the path where are located the various
            *device family directories*.
        """
        return self._root_dir.joinpath(self._layout.family_set_dir_name)

    @property
    def ssh_auth_dir(self) -> Path:
        return self._root_dir.joinpath(self._layout.ssh_auth_dir_name)

    def get_instance_dir_for(self, device_id: str) -> Path:
        return self.instance_set_dir.joinpath(device_id)

    def get_instance_paths_for(self, device_id: str) -> DeviceCfgRepoInstancePaths:
        instance_dir = self.get_instance_dir_for(device_id)
        return DeviceCfgRepoInstancePaths(instance_dir, self._layout.instance_dir)

    def get_type_dir_for(self, device_type: str) -> Path:
        return self.type_set_dir.joinpath(device_type)


class DeviceCfgRepoPathsGivenInstance(DeviceCfgRepoPaths):
    """Paths to various well known locations of a device
        configuration repository with additionel device
        specific knowledge.

    Same as `DeviceCfgRepoPaths` but now, we know the particular
    device and as such can directly return specific information
    about it (e.g.: its instance and type dir, etc).
    """
    def __init__(
            self,
            root_dir: Path,
            layout: DeviceCfgRepoLayout,
            instance_id_w_type: DeviceIdWType
    ) -> None:
        super().__init__(root_dir, layout)
        self._instance_id_w_type = instance_id_w_type

    @property
    def instance_dir(self) -> Path:
        return self.get_instance_dir_for(self._instance_id_w_type.id)

    @property
    def instance_paths(self) -> DeviceCfgRepoInstancePaths:
        return self.get_instance_paths_for(self._instance_id_w_type.id)

    @property
    def type_dir(self) -> Path:
        return self.get_type_dir_for(self._instance_id_w_type.type)


def get_device_cfg_repo_paths(
        root_dir: Optional[Path] = None,
        layout: Optional[DeviceCfgRepoLayout] = None
) -> DeviceCfgRepoPaths:
    if root_dir is None:
        root_dir = get_device_cfg_repo_root_dir_path()
    layout = ensure_device_cfg_repo_layout_or_default(layout)
    return DeviceCfgRepoPaths(root_dir, layout)


def get_device_cfg_repo_paths_given_instance(
        device_id: str,
        device_type: Optional[str],
        root_dir: Optional[Path] = None,
        layout: Optional[DeviceCfgRepoLayout] = None
) -> DeviceCfgRepoPathsGivenInstance:
    if root_dir is None:
        root_dir = get_device_cfg_repo_root_dir_path()
    layout = ensure_device_cfg_repo_layout_or_default(layout)

    if device_type is None:
        device_info_filename = root_dir.joinpath(
            layout.instance_set_dir_name).joinpath(
                layout.instance_dir.info_file_stem).with_suffix(
                    layout.instance_dir.info_file_ext)

        device_type = load_device_type_from_device_info_file(
            device_info_filename)

    instance_id_w_type = DeviceIdWType(device_id, device_type)
    return DeviceCfgRepoPathsGivenInstance(
        root_dir, layout, instance_id_w_type)
