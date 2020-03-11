from typing import List
from pathlib import Path


def touch_file(filename: Path) -> None:
    with open(filename, "w"):
        pass


def write_file_content(filename: Path, lines: List[str]) -> None:
    with open(filename, "w") as f:
        f.writelines(lines)
