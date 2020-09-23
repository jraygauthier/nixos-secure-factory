from dataclasses import dataclass

from .trust_types import GpgTrust, GpgOwnerTrust

GpgKeyFprT = str


@dataclass
class GpgKeyWEmail:
    fpr: GpgKeyFprT
    email: str


@dataclass
class GpgKeyWTrust:
    fpr: GpgKeyFprT
    trust: GpgTrust


@dataclass
class GpgKeyWUIOwnerTrust:
    fpr: GpgKeyFprT
    trust: GpgOwnerTrust


@dataclass
class GpgKeyExtInfo:
    email: str
    user_name: str
    trust: GpgTrust


@dataclass
class GpgKeyExtInfoWOTrust(GpgKeyExtInfo):
    otrust: GpgTrust


@dataclass
class GpgKeyWExtInfo:
    fpr: GpgKeyFprT
    info: GpgKeyExtInfo


@dataclass
class GpgKeyWExtInfoWOTrust:
    fpr: GpgKeyFprT
    info: GpgKeyExtInfoWOTrust
