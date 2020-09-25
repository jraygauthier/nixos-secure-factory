from pathlib import Path

from .file_device_state import DeviceStateFile


class CurrentDeviceStateFile(DeviceStateFile):
    def __init__(self, filename: Path) -> None:
        super().__init__(filename)
