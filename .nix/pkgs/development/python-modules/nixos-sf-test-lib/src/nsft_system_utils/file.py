from typing import Iterable, List, Iterator
from pathlib import Path


def touch_file(filename: Path) -> None:
    with open(filename, "w"):
        pass


def write_text_file_content(filename: Path, lines: Iterable[str]) -> None:
    with open(filename, "w") as f:
        for l in lines:
            f.write(f"{l}\n")


def read_text_file_content_it(filename: Path) -> Iterator[str]:
    with open(filename) as f:
        for l in map(lambda x: x.rstrip("\n"), f.readlines()):
            yield l


def read_text_file_content(filename: Path) -> List[str]:
    return list(read_text_file_content_it(filename))
