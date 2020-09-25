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
    the information provided via its *device state file*.

 -  *device instance directory*:

    The directory that contain information about a specific device.

    Usually found at `[repo]/device/[my-device-name]/`.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device/demo-virtual-box-vm/`.

 -  *device state file*:

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
    *device state file*.

    A *device type* can *optionally* belong to a *type family*

 -  *device type directory*

    The directory where the nixos configuration for a device usually starts.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device-type/virtual-box-vm/`.

 -  *device family*:

    The type of the device type if any.

    This allows to share some configurations between types_device.

    E.g:
    `[nixos-secure-factory]/demo-nixos-config/device-family/generic/`.

TODO:

 -  This should pave the way for the eventuallity of an optional repo layout
    configuration file, potentially found at the root of the repository.
"""
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, Optional

from .file_device_state import (
    DeviceState,
    DeviceStateFile,
    DeviceStateFileError,
    DeviceStatePlainT,
)
from .repo_ssh_auth import SshAuthRepo
from .types_device import (
    DeviceInstanceStateFileAccessError,
    DeviceInstanceStateAccessError,
    DeviceInstanceWIdWTypeWStateWStateFile,
    DeviceTypeWId,
    get_device_instance_err_cls_from_device_state_file_err,
)

assert DeviceInstanceStateAccessError
assert DeviceInstanceStateFileAccessError


def _get_default_device_cfg_repo_root_dir() -> Path:
    env_var_name = "PKG_NSF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR"
    out = os.environ.get(env_var_name, None)
    if out is None:
        raise Exception((
            "ERROR: Env var '{}' "
            "should be set to point to the device "
            "configuration repository!").format(
                env_var_name)
        )

    return Path(out)


@dataclass
class DeviceCfgRepoInstanceDirLayout:
    """The layout of the per device directory.

    The layout of a *device instance directory* usually found at
    `[repo]/device/[my-device-name]/`.

    See module docstring for definition of the concept and examples.
    """
    state_file_stem: str
    state_file_ext: str
    ssh_auth_dir_name: str

    @classmethod
    def mk_default(cls) -> 'DeviceCfgRepoInstanceDirLayout':
        return cls(
            state_file_stem="device",
            state_file_ext="json",
            ssh_auth_dir_name="ssh"
        )


@dataclass
class DeviceCfgRepoTypeDirLayout:
    @classmethod
    def mk_default(cls) -> 'DeviceCfgRepoTypeDirLayout':
        return cls()


@dataclass
class DeviceCfgRepoLayout:
    """The layout of a device config repository.

    This allows one to describe how the repository is
    structured, potentially diverging from the default
    layout.
    """
    instance_dir: DeviceCfgRepoInstanceDirLayout
    type_dir: DeviceCfgRepoTypeDirLayout
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
            type_dir=DeviceCfgRepoTypeDirLayout.mk_default(),
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


class DeviceCfgRepoType(DeviceTypeWId):
    """Paths to various well known locations inside a device
        type directory.

    A device type directory is usually found at
    `[repo]/device-type/[my-device-type-id]/`.
    """
    def __init__(
            self,
            type_dir: Path,
            dir_layout: DeviceCfgRepoTypeDirLayout,
            type_id: str,
    ) -> None:
        self._type_id = type_id
        self._type_dir = type_dir
        self._dir_layout = dir_layout

    @property
    def id(self) -> str:
        return self._type_id

    @property
    def dir(self) -> Path:
        return self._type_dir


class DeviceCfgRepoInstance(DeviceInstanceWIdWTypeWStateWStateFile):
    """Paths to various well known locations inside a device
        instance directory.

    A device instance directory is usually found at
    `[repo]/device/[my-device-id]/`.
    """
    def __init__(
            self,
            instance_dir: Path,
            dir_layout: DeviceCfgRepoInstanceDirLayout,
            instance_id: str,
            instance_type: Optional[str]
    ) -> None:
        self._dir = instance_dir
        self._dir_layout = dir_layout
        self._id = instance_id
        self._type = instance_type

    @property
    def id(self) -> str:
        return self._id

    @property
    def type_id(self) -> str:
        """Returns the type of the instance (*device type*).

        Raises:
            DeviceInstanceStateFileAccessError:
                When the fields cannot be retrieved for some reason.
        """

        if self._type is not None:
            return self._type

        try:
            self._type = self.state_file.load_field_type()
        except DeviceStateFileError as e:
            ECls = get_device_instance_err_cls_from_device_state_file_err(e)
            raise ECls(
                f"Cannot retrieve the 'type' field because: {str(e)}"
            ) from e

        return self._type

    @property
    def dir(self) -> Path:
        return self._dir

    @property
    def state_file(self) -> DeviceStateFile:
        """Path to the *device state file* / device instance's state file.
        Usually found at `[my-device-instance-dir]/device.json`.
        """
        return DeviceStateFile(
            self._dir.joinpath(
                self._dir_layout.state_file_stem).with_suffix(
                    f".{self._dir_layout.state_file_ext}")
        )

    @property
    def state(self) -> DeviceState:
        """Returns the state for the instance.
        """
        try:
            return self.state_file.load()
        except DeviceStateFileError as e:
            ECls = get_device_instance_err_cls_from_device_state_file_err(e)
            raise ECls(
                f"Cannot retrieve the state because: {str(e)}"
            ) from e

    @property
    def state_plain(self) -> DeviceStatePlainT:
        """Returns the state for the instance.
        """
        try:
            return self.state_file.load_plain()
        except DeviceStateFileError as e:
            ECls = get_device_instance_err_cls_from_device_state_file_err(e)
            raise ECls(
                f"Cannot retrieve the plain state because: {str(e)}"
            ) from e

    @property
    def ssh_auth(self) -> SshAuthRepo:
        return SshAuthRepo(
            self._dir.joinpath(self._dir_layout.ssh_auth_dir_name))


class DeviceCfgRepo:
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
    def dir(self) -> Path:
        """Return this repository's root directory.
        """
        return self._root_dir

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
    def ssh_auth(self) -> SshAuthRepo:
        return SshAuthRepo(
            self._root_dir.joinpath(self._layout.ssh_auth_dir_name))

    def get_instance_dir_for(self, instance_id: str) -> Path:
        return self.instance_set_dir.joinpath(instance_id)

    def get_instance_for(
            self, instance_id: str, instance_type: Optional[str] = None
    ) -> DeviceCfgRepoInstance:
        instance_dir = self.get_instance_dir_for(instance_id)
        return DeviceCfgRepoInstance(
            instance_dir, self._layout.instance_dir, instance_id, instance_type)

    def iter_instance_dirs(self) -> Iterator[Path]:
        for fn in self.instance_set_dir.iterdir():
            if fn.is_dir():
                yield fn

    def iter_instances(self) -> Iterator[DeviceCfgRepoInstance]:
        for instance_dir in self.iter_instance_dirs():
            instance_id = instance_dir.name
            # TODO: Check if valid id and skip if isn't so.
            yield DeviceCfgRepoInstance(
                instance_dir, self._layout.instance_dir, instance_id, None)

    def get_type_dir_for(self, type_id: str) -> Path:
        return self.type_set_dir.joinpath(type_id)

    def get_type_for(
            self, type_id: str
    ) -> DeviceCfgRepoType:
        type_dir = self.get_type_dir_for(type_id)
        return DeviceCfgRepoType(type_dir, self._layout.type_dir, type_id)


def mk_device_cfg_repo(
        root_dir: Optional[Path] = None,
        layout: Optional[DeviceCfgRepoLayout] = None
) -> DeviceCfgRepo:
    if root_dir is None:
        root_dir = _get_default_device_cfg_repo_root_dir()
    layout = ensure_device_cfg_repo_layout_or_default(layout)
    return DeviceCfgRepo(root_dir, layout)
