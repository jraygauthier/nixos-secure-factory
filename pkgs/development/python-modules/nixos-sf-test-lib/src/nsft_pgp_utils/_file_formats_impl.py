from typing import Iterator
from .types import GpgKeyWTrust


def _parse_otrust_content_it(content: str) -> Iterator[GpgKeyWTrust]:
    lines = map(str.lstrip, content.splitlines())
    for l in lines:
        if l.startswith("#"):
            continue

        key_str, lvl_str, _ = map(str.strip, l.split(":", maxsplit=2))
        assert 40 == len(key_str)
        lvl = int(lvl_str)
        assert 0 <= lvl and 6 >= lvl
        yield GpgKeyWTrust(key_str, int(lvl_str))
