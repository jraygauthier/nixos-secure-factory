from dataclasses import dataclass


@dataclass
class GpgKeyWEmail:
    key: str
    email: str


@dataclass
class GpgKeyWTrust:
    key: str
    trust_level: int
