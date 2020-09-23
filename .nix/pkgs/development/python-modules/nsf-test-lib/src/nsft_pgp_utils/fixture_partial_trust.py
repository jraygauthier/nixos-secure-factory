
from dataclasses import dataclass
from .fixture_encrypt_decrypt import GpgEncryptDecryptBasicFixture
from .ctx_types import GpgContextWExtInfo


@dataclass
class GpgPartialTrustFixture:
    # External trust network.
    et_net: GpgEncryptDecryptBasicFixture

    # Partially part of the trust network.
    #
    # All of those have a secret id but they only know a subset of the above
    # trust net, the above trust net itself know nothing about them.
    #
    # This is a normal situation, this is where one beguns with pgp trust net.
    #
    p_ka: GpgContextWExtInfo  # Knows a
    p_kb: GpgContextWExtInfo  # Knows b
    p_ke: GpgContextWExtInfo  # Knows e
    p_kab: GpgContextWExtInfo  # Knows a and b
    p_kae: GpgContextWExtInfo  # Knows a and e
    p_kbe: GpgContextWExtInfo  # Knows b and e
    p_kabe: GpgContextWExtInfo  # Knows a, b and e but not other ks
    p_kak: GpgContextWExtInfo  # Knows a and other ks
    p_kbk: GpgContextWExtInfo  # Knows a, b and other ks
    p_kek: GpgContextWExtInfo  # Knows e and other ks
    # TODO Consider other cases with other trust levels and indirect signatures:
    #  -  a signed b but k only signed a. does k trust b?


# TODO: Implement this. This is an ongoing construction site kept to write down
# some ideas for the time being.
