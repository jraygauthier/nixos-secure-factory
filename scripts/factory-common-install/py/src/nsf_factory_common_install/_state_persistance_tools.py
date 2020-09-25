from pathlib import Path
from typing import Dict, Any, Iterator

import json
import yaml


class StateFileError(Exception):
    pass


class StateFileAccessError(StateFileError):
    pass


class StateFileFormatError(StateFileError):
    pass


StatePlainT = Dict[str, Any]


def _load_state_from_json_file_plain(
        filename: Path) -> StatePlainT:

    try:
        with open(filename) as f:
            # We want to preserve key order. Json already does that.
            out = json.load(f)
    except FileNotFoundError as e:
        raise StateFileAccessError(str(e))
    except json.decoder.JSONDecodeError as e:
        raise StateFileFormatError(f"Not a valid json file: {str(e)}") from e

    assert out is not None
    return out


def _load_state_from_yaml_file_plain(
        filename: Path) -> StatePlainT:
    try:
        with open(filename) as f:
            # We want to preserve key order.
            # Yaml already does that on load.
            out = yaml.safe_load(f)
    except FileNotFoundError as e:
        raise StateFileAccessError(str(e))

    assert out is not None
    return out


def load_state_from_file_plain(
        filename: Path) -> StatePlainT:
    if ".yaml" == filename.suffix:
        return _load_state_from_yaml_file_plain(filename)

    assert ".json" == filename.suffix
    return _load_state_from_json_file_plain(filename)


def _dump_plain_state_to_yaml_file(
        state: StatePlainT,
        out_filename: Path
) -> None:
    with open(out_filename, 'w') as of:
        # We want to preserve key order, thus the `sort_keys=False`.
        yaml.safe_dump(state, of, sort_keys=False)


def _dump_state_to_json_file(
        state: StatePlainT,
        out_filename: Path
) -> None:
    with open(out_filename, 'w') as of:
        # We want to preserve key order, thus the `sort_keys=False`.
        json.dump(
            state,
            of,
            sort_keys=False,
            indent=2,
            separators=(',', ': ')
        )


def dump_plain_state_to_file(
        state: StatePlainT,
        out_filename: Path
) -> None:
    if ".yaml" == out_filename.suffix:
        return _dump_plain_state_to_yaml_file(state, out_filename)

    assert ".json" == out_filename.suffix
    return _dump_state_to_json_file(state, out_filename)


def dump_plain_state_as_yaml_lines(
        state: StatePlainT,
) -> Iterator[str]:
    # TODO: Find a way to perform the dump iteratively / in a
    # streaming fashion.
    out_str = yaml.safe_dump(state, sort_keys=False)
    for l in out_str.splitlines(keepends=True):
        yield l


def format_plain_state_as_yaml_str(
        state: StatePlainT) -> str:
    if not state:
        return ""

    return "".join(dump_plain_state_as_yaml_lines(state))
