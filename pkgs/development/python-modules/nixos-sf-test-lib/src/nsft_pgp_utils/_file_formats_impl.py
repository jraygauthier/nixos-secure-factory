from typing import Iterator

from .key_types import GpgKeyWTrust
from .trust_types import (
    convert_gpg_exp_to_calc_trust,
    mk_gpg_exp_trust_from_exported_field_value,
)


def _parse_otrust_content_it(content: str) -> Iterator[GpgKeyWTrust]:
    lines = map(str.lstrip, content.splitlines())
    for l in lines:
        if l.startswith("#"):
            continue

        key_str, lvl_str, _ = map(str.strip, l.split(":", maxsplit=2))
        assert 40 == len(key_str)
        lvl_str = lvl_str.strip()
        exp_trust = mk_gpg_exp_trust_from_exported_field_value(lvl_str)
        trust = convert_gpg_exp_to_calc_trust(exp_trust)
        yield GpgKeyWTrust(key_str, trust)
