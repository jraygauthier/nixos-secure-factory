from dataclasses import dataclass
from typing import Dict, Any, Optional, List, NamedTuple

DeviceStatePlainT = Dict[str, Any]


class DeviceIdWType(NamedTuple):
    id: str
    type: str


@dataclass
class DeviceState:
    id: str
    type: str
    serial_number: str
    hostname: str
    ssh_port: str
    gpg_id: Optional[str]
    factory_installed_by: Optional[List[str]]
