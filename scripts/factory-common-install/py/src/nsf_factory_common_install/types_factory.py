
from abc import ABC, abstractmethod
from .types_factory_state import (
    FactoryState, FactoryStatePlainT
)
from .file_factory_state import FactoryStateFile


class FactoryError(Exception):
    pass


class FactoryMissingFieldsError(FactoryError):
    pass


class FactoryUnspecifiedError(FactoryError):
    pass


class FactoryWUserId(ABC):
    @property
    @abstractmethod
    def user_id(self) -> str:
        """Returns the factory's user id.

        Raises:
            FactoryMissingFieldsError: When the user id information
                cannot be retrieved for some reason.
        """
        pass


class FactoryWState(ABC):
    @property
    @abstractmethod
    def state(self) -> FactoryState:
        """Returns the state for the factory.

        Raises:
            FactoryMissingFieldsError: When the state information
                cannot be retrieved for some reason.
        """
        pass

    @property
    @abstractmethod
    def state_plain(self) -> FactoryStatePlainT:
        """Returns the plain state for the factory.

        Raises:
            FactoryMissingFieldsError: When the plain state
                information cannot be retrieved for some reason.
        """
        pass


class FactoryWStateFile(ABC):
    @property
    @abstractmethod
    def state_file(self) -> FactoryStateFile:
        """The factory state file.
        """
        pass


class FactoryWUserIdWState(
        FactoryWUserId, FactoryWState):
    pass


class FactoryWUserIdWStateWStateFile(
        FactoryWUserIdWState, FactoryWStateFile):
    pass
