from dataclasses import dataclass
from typing import Dict, Any


FactoryStatePlainT = Dict[str, Any]


@dataclass
class FactoryStateUser:
    id: str
    full_name: str
    email: str


@dataclass
class FactoryState:
    user: FactoryStateUser
