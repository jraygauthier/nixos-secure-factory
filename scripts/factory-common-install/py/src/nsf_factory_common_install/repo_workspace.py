import os
from pathlib import Path
from typing import Optional

from .file_current_device_state import CurrentDeviceStateFile
from .file_factory_state import FactoryStateFile, FactoryStateFileError

from .types_device import (
    DeviceInstanceStateAccessError,
    DeviceInstanceStateFileAccessError,
    DeviceInstanceWIdWTypeWStateWStateFile,
    DeviceState,
    DeviceStateFileError,
    DeviceStatePlainT,
    get_device_instance_err_cls_from_device_state_file_err,
)
from .types_factory import (
    FactoryMissingFieldsError,
    FactoryState,
    FactoryStatePlainT,
    FactoryWUserIdWStateWStateFile,
)


# re-export.
assert DeviceInstanceStateAccessError
assert DeviceInstanceStateFileAccessError


def _get_default_workspace_dir_path() -> Path:
    """Return the path to the workspace directory.

    The workspace directory is where the nixos-secure-factory data
    (such as the currently checked-out device) live.

    This function attempts to provide a serie of fallbacks
    for this location depending on the use case.

    **IMPORTANT**: Always keep in sync with:
    `scripts/factory-common-install/bin/pkg-nsf-factory-common-install-get-workspace-dir`.
    """
    env_var_name = "PKG_NSF_FACTORY_COMMON_INSTALL_WORKSPACE_DIR"
    env_var_value = os.environ.get(env_var_name, None)

    if env_var_value is not None:
        env_var_path = Path(env_var_value)
        env_var_path.stat()
        return env_var_path

    script_dir = Path(__name__).parent
    user_home_ws_dir = Path.home().joinpath(".nixos-secure-factory")

    if str(script_dir).startswith("/nix/store"):
        # In the installed case, we systematically use the user home ws dir.
        return user_home_ws_dir

    # In the developer case, we attempt to use this repository's parent
    # directory as ws.
    repo_parent_ws_dir = script_dir.joinpath("../../../../../..").resolve()

    if os.access(repo_parent_ws_dir, os.R_OK | os.W_OK):
        return repo_parent_ws_dir

    # That is, unless we get no rw access in which case we
    # fallback to the user home ws option.
    return user_home_ws_dir


class WorkspaceRepoFactory(FactoryWUserIdWStateWStateFile):
    def __init__(self, state_filename: Path) -> None:
        self._state_file = FactoryStateFile(state_filename)

    @property
    def user_id(self) -> str:
        """Returns the factory's user id.

        Raises:
            FactoryMissingFieldsError: When the user id information
                cannot be retrieved for some reason.
        """
        try:
            return self._state_file.load_user().id
        except FactoryStateFileError as e:
            raise FactoryMissingFieldsError(
                f"Cannot retrieve the 'user_id' field because: {str(e)}"
            ) from e

    @property
    def state(self) -> FactoryState:
        """Returns the state for the factory.

        Raises:
            FactoryMissingFieldsError: When the state information
                cannot be retrieved for some reason.
        """
        try:
            return self._state_file.load()
        except FactoryStateFileError as e:
            raise FactoryMissingFieldsError(
                f"Cannot retrieve the state because: {str(e)}"
            ) from e

    @property
    def state_plain(self) -> FactoryStatePlainT:
        """Returns the plain state for the factory.

        Raises:
            FactoryMissingFieldsError: When the plain state
                information cannot be retrieved for some reason.
        """
        try:
            return self._state_file.load_plain()
        except FactoryStateFileError as e:
            raise FactoryMissingFieldsError(
                f"Cannot retrieve the plain state because: {str(e)}"
            ) from e

    @property
    def state_file(self) -> FactoryStateFile:
        """The workspace's factory state file.
        """
        return self._state_file


class WorspaceRepoCurrentDevice(DeviceInstanceWIdWTypeWStateWStateFile):
    def __init__(self, state_filename: Path) -> None:
        self._state_file = CurrentDeviceStateFile(state_filename)

    @property
    def id(self) -> str:
        """Returns the identifier for the currently checked-out device.

        Raises:
            DeviceInstanceStateFileAccessError:
                When the current device file does not exits.
        """
        try:
            return self.state_file.load_field_id()
        except DeviceStateFileError as e:
            ECls = get_device_instance_err_cls_from_device_state_file_err(e)
            raise ECls(
                f"Cannot retrieve the 'id' field because: {str(e)}"
            ) from e

    @property
    def type_id(self) -> str:
        """Returns the type identifier of the currently checked-out device.

        Raises:
            DeviceInstanceStateFileAccessError:
                When the current device file does not exits.
        """
        try:
            return self.state_file.load_field_type()
        except DeviceStateFileError as e:
            ECls = get_device_instance_err_cls_from_device_state_file_err(e)
            raise ECls(
                f"Cannot retrieve the 'type' field because: {str(e)}"
            ) from e

    @property
    def state_file(self) -> CurrentDeviceStateFile:
        """The workspace's current device state file.
        """
        return self._state_file

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


class WorkspaceRepo:
    """The workspace content repository.
    """
    def __init__(self, dir: Path):
        self._dir = dir

    @property
    def dir(self) -> Path:
        return self._dir

    @property
    def factory(self) -> WorkspaceRepoFactory:
        # TODO: Rename to `.nsf-factory.yaml` or `.nsf-factory-state.yaml`.
        return WorkspaceRepoFactory(
            self.dir.joinpath(".factory-info.yaml"))

    @property
    def current_device(self) -> WorspaceRepoCurrentDevice:
        # TODO: Rename to `.nsf-current-device.yaml` or
        # `.nsf-current-device-state.yaml`.
        return WorspaceRepoCurrentDevice(
            self.dir.joinpath(".current-device.yaml"))


def mk_workspace_repo(
        dir: Optional[Path] = None
) -> WorkspaceRepo:

    if dir is None:
        dir = _get_default_workspace_dir_path()

    return WorkspaceRepo(dir)
