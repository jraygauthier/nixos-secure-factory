
from enum import Enum, IntEnum, auto


# This is the trust level as specified by the kingring owner via cli / gui.
class GpgOwnerTrust(IntEnum):
    Unknown = 0
    Undefined = 1
    Never = 2
    Marginal = 3
    Fully = 4
    Ultimate = 5


# Same as `GpgOwnerTrust` but corresponding to the exported integers levels
# (i.e: `--export-ownertrust`).
class GpgExportedOwnerTrust(IntEnum):
    Unknown0 = 0
    Unknown1 = 1
    Undefined = 2
    Never = 3
    Marginal = 4
    Fully = 5
    Ultimate = 6


# Also named: Calculated trust. This is the effective trust.
class GpgTrust(Enum):
    KeyUnknown = auto()
    KeyInvalid = auto()
    KeyDisabled = auto()
    KeyRevoked = auto()
    KeyExpired = auto()
    TrustUnknown = auto()
    TrustUndefined = auto()
    TrustNever = auto()
    TrustMarginal = auto()
    TrustFully = auto()
    TrustUltimate = auto()


def mk_gpg_exp_trust_from_exported_field_value(
        field_val: str) -> GpgExportedOwnerTrust:
    i_val = int(field_val)
    return GpgExportedOwnerTrust(i_val)


def mk_gpg_calc_trust_from_colon_sep_field_value(
        field_val: str) -> GpgTrust:
    E = GpgTrust
    m = {
        'o': E.KeyUnknown,
        'i': E.KeyInvalid,
        'd': E.KeyDisabled,
        'r': E.KeyRevoked,
        'e': E.KeyExpired,
        '-': E.TrustUnknown,
        'q': E.TrustUndefined,
        'n': E.TrustNever,
        'm': E.TrustMarginal,
        'f': E.TrustFully,
        'u': E.TrustUltimate
    }

    return m[field_val]


def convert_gpg_exp_to_calc_trust(
        in_val: GpgExportedOwnerTrust) -> GpgTrust:
    IE = GpgExportedOwnerTrust
    OE = GpgTrust
    m = {
        IE.Unknown0: OE.TrustUnknown,
        IE.Unknown1: OE.TrustUnknown,
        IE.Undefined: OE.TrustUndefined,
        IE.Never: OE.TrustNever,
        IE.Marginal: OE.TrustMarginal,
        IE.Fully: OE.TrustFully,
        IE.Ultimate: OE.TrustUltimate
    }

    return m[in_val]


def convert_gpg_otrust_to_exp_otrust(
        in_val: GpgOwnerTrust) -> GpgExportedOwnerTrust:
    IE = GpgOwnerTrust
    OE = GpgExportedOwnerTrust
    m = {
        IE.Unknown: OE.Unknown1,
        IE.Undefined: OE.Undefined,
        IE.Never: OE.Never,
        IE.Marginal: OE.Marginal,
        IE.Fully: OE.Fully,
        IE.Ultimate: OE.Ultimate
    }

    return m[in_val]
