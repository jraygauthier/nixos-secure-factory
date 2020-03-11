from typing import List


def touch_file(filename: str) -> None:
    with open(filename, "w"):
        pass


def write_file_content(filename: str, lines: List[str]) -> None:
    with open(filename, "w") as f:
        f.writelines(lines)
