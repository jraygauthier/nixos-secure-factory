"""A couple of abstract types to access device related information.

Most of these should instead be protocol (structural typing) once we're
using py38.
"""

from abc import ABC, abstractmethod
from typing import Type

from .file_device_state import (
    DeviceStateFile,
    DeviceStateFileAccessError,
    DeviceStateFileError,
)
from .types_device_state import DeviceState, DeviceStatePlainT


class DeviceInstanceError(Exception):
    pass


class DeviceInstanceUnspecifiedError(
        DeviceInstanceError):
    pass


class DeviceInstanceStateAccessError(
        DeviceInstanceError):
    pass


class DeviceInstanceStateFileAccessError(
        DeviceInstanceStateAccessError):
    pass


def get_device_instance_err_cls_from_device_state_file_err(
        e: DeviceStateFileError) -> Type[DeviceInstanceStateAccessError]:
    if isinstance(e, DeviceStateFileAccessError):
        return DeviceInstanceStateFileAccessError

    return DeviceInstanceStateAccessError


class DeviceInstanceWId(ABC):
    @property
    @abstractmethod
    def id(self) -> str:
        """Returns the device identifier of the instance.

        Raises:
            DeviceInstanceStateAccessError: When the device id information
                cannot be retrieved for some reason.
        """
        pass


class DeviceInstanceWType(ABC):
    @property
    @abstractmethod
    def type_id(self) -> str:
        """Returns the type identifier of the instance.

        Raises:
            DeviceInstanceStateAccessError: When the type information
                cannot be retrieved for some reason.
        """

        pass


class DeviceInstanceWState(ABC):
    @property
    @abstractmethod
    def state(self) -> DeviceState:
        """Returns the state for the instance.

        Raises:
            DeviceInstanceStateAccessError: When the state information
                cannot be retrieved for some reason.
        """
        pass

    @property
    @abstractmethod
    def state_plain(self) -> DeviceStatePlainT:
        """Returns the state for the instance.

        Raises:
            DeviceInstanceStateAccessError: When the plain state
                information cannot be retrieved for some reason.
        """
        pass


class DeviceInstanceWStateFile(ABC):
    @property
    @abstractmethod
    def state_file(self) -> DeviceStateFile:
        """Returns the state file for the instance.

        Should never raise the interface supports returning a file that does not
        exists yet. However, some of the returned interface might raise.
        """
        pass


class DeviceInstanceWIdWType(
        DeviceInstanceWId, DeviceInstanceWType):
    pass


class DeviceInstanceWIdWTypeWState(
        DeviceInstanceWIdWType, DeviceInstanceWState):
    pass


class DeviceInstanceWIdWTypeWStateWStateFile(
        DeviceInstanceWIdWTypeWState, DeviceInstanceWStateFile):
    pass


class DeviceTypeWId:
    @property
    @abstractmethod
    def id(self) -> str:
        pass
