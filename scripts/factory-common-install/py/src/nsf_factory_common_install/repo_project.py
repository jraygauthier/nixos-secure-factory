from abc import abstractmethod
from typing import Optional

from .file_device_state import DeviceStateFileError
from .repo_device_cfg import DeviceCfgRepo, DeviceCfgRepoInstance, mk_device_cfg_repo
from .repo_workspace import (
    WorkspaceRepo,
    WorkspaceRepoFactory,
    WorspaceRepoCurrentDevice,
    mk_workspace_repo,
)
from .types_device import (
    DeviceInstanceUnspecifiedError,
    DeviceInstanceWIdWTypeWStateWStateFile,
    DeviceState,
    DeviceStateFile,
    DeviceStatePlainT,
)


ProjectFactory = WorkspaceRepoFactory


class ProjectRepoDevice(DeviceInstanceWIdWTypeWStateWStateFile):
    @property
    @abstractmethod
    def id(self) -> str:
        pass

    @property
    @abstractmethod
    def type_id(self) -> str:
        pass

    @property
    @abstractmethod
    def state_file(self) -> DeviceStateFile:
        pass

    @property
    @abstractmethod
    def state(self) -> DeviceState:
        pass

    @property
    @abstractmethod
    def state_plain(self) -> DeviceStatePlainT:
        pass

    @abstractmethod
    def get_instance_from_default_repo(
            self) -> DeviceCfgRepoInstance:
        """Return the corresponding instance from the default
            device repository.

        Raises:
            DeviceInstanceUnspecifiedError:
                When for some reason the corresponding device cannot
                be determined / inferred (most likely because the current
                device state file does not exits).
        """
        pass

    def get_instance_from_default_repo_opt(
            self) -> Optional[DeviceCfgRepoInstance]:
        """Return the corresponding instance from the default
            device repository or `None` when unspecified.

        See `get_instance_from_default_repo` for the variant raising
        exceptions.
        """
        try:
            return self.get_instance_from_default_repo()
        except DeviceInstanceUnspecifiedError:
            return None


class ProjectRepoDefaultDevice(ProjectRepoDevice):
    def __init__(
            self,
            device_id: str,
            default_repo: DeviceCfgRepo
    ) -> None:
        self._default_repo = default_repo
        self._default_repo_instance = default_repo.get_instance_for(device_id)

    @property
    def id(self) -> str:
        return self._default_repo_instance.id

    @property
    def type_id(self) -> str:
        return self._default_repo_instance.type_id

    @property
    def state_file(self) -> DeviceStateFile:
        return self._default_repo_instance.state_file

    @property
    def state(self) -> DeviceState:
        return self._default_repo_instance.state

    @property
    def state_plain(self) -> DeviceStatePlainT:
        return self._default_repo_instance.state_plain

    def get_instance_from_default_repo(
            self) -> DeviceCfgRepoInstance:
        return self._default_repo_instance

    # IDEA: `get_instance_from_repo("repo-id")`.
    # IDEA: We could implement a repo override scheme for the fields.


class ProjectRepoCurrentDevice(ProjectRepoDevice):
    """The interface for accessing the current device of a project.

    Currently identical to the project device. However, this is
    a placeholder for any current device specific additions.
    """
    pass


class ProjectRepoDefaultCurrentDevice(ProjectRepoCurrentDevice):
    def __init__(
            self,
            ws_device: WorspaceRepoCurrentDevice,
            default_repo: DeviceCfgRepo
    ) -> None:
        self._ws_device = ws_device
        self._default_repo = default_repo

    @property
    def id(self) -> str:
        return self._ws_device.id

    @property
    def type_id(self) -> str:
        return self._ws_device.type_id

    @property
    def state_file(self) -> DeviceStateFile:
        return self._ws_device.state_file

    @property
    def state(self) -> DeviceState:
        return self._ws_device.state

    @property
    def state_plain(self) -> DeviceStatePlainT:
        return self._ws_device.state_plain

    def get_instance_from_default_repo(
            self) -> DeviceCfgRepoInstance:
        try:
            device_id = self._ws_device.state_file.load_field_id()
        except DeviceStateFileError as e:
            raise DeviceInstanceUnspecifiedError(
                "Cannot determine the current device because: "
                f"{str(e)}"
            )

        return self._default_repo.get_instance_for(device_id)

    # IDEA: `get_instance_from_repo("repo-id")`.
    # IDEA: We could implement a repo override scheme for the fields.


class ProjectRepo:
    """The whole project repo set seen as a whole."""

    @property
    @abstractmethod
    def workspace(self) -> WorkspaceRepo:
        """Return the workspace repository for this project."""
        pass

    @property
    @abstractmethod
    def device_cfg(self) -> DeviceCfgRepo:
        """Return the (default) device configuration repository
            for this project."""
        pass

    @property
    @abstractmethod
    def factory(self) -> ProjectFactory:
        """Return the factory associated to this project.

        Mostly information about the user driving this nsf.
        """
        pass

    @property
    @abstractmethod
    def current_device(self) -> ProjectRepoCurrentDevice:
        """Return a high level interface to the currently checked out device
            for this project."""
        pass

    @abstractmethod
    def get_device_by_id(
            self, device_id: str) -> ProjectRepoDevice:
        """Return a high level interface to a specific device for
            this project."""
        pass


class ProjectDefaultRepo(ProjectRepo):
    """The whole project repo set (default version) seen as a whole.
    """
    def __init__(
            self,
            workspace: WorkspaceRepo,
            device_cfg: DeviceCfgRepo
    ) -> None:
        self._workspace = workspace
        self._device_cfg = device_cfg

    @property
    def workspace(self) -> WorkspaceRepo:
        return self._workspace

    @property
    def device_cfg(self) -> DeviceCfgRepo:
        return self._device_cfg

    @property
    def factory(self) -> ProjectFactory:
        return self._workspace.factory

    @property
    def current_device(self) -> ProjectRepoCurrentDevice:
        return ProjectRepoDefaultCurrentDevice(
            self._workspace.current_device, self.device_cfg)

    def get_device_by_id(
            self, device_id: str) -> ProjectRepoDevice:
        return ProjectRepoDefaultDevice(
            device_id, self.device_cfg)


def mk_project_repo(
        workspace: Optional[WorkspaceRepo] = None,
        device_cfg: Optional[DeviceCfgRepo] = None
) -> ProjectRepo:
    """Create a nsf project repository instance.

    This helper factory function allow one to create a default
    instance when specifying no parameters changing only what
    needs to differ from the defaults.

    This is usually the entry point for accessing any information
    about the project.

    Any cli / gui should start by creating / customizing its project
    instance and from there pass the instance or any subset
    of it around.

    Doing this, it should be easy to have a centralize way to
    configure specialized nsf projects.
    """
    # IDEA: Load customizations from a `.nsf-project.yaml` file at
    # the root of the repo. Theses would allow us not to depend on any
    # environment variables. Instead, the env var would allow one to
    # override specific fields.

    if workspace is None:
        workspace = mk_workspace_repo()

    if device_cfg is None:
        device_cfg = mk_device_cfg_repo()

    return ProjectDefaultRepo(workspace, device_cfg)
