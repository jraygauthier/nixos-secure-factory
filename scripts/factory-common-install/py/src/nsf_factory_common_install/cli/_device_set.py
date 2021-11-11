from typing import Iterable, List, TypeVar

from nsf_factory_common_install.types_device import DeviceInstanceWId

_T = TypeVar("_T", bound=DeviceInstanceWId)


class MatchNotUniqueError(Exception):
    pass


def match_device_by_id(
        search_str: str, available_devices: Iterable[_T]
) -> List[_T]:
    out = [x for x in available_devices if x.id.startswith(search_str)]
    if out:
        return out

    return [x for x in available_devices if search_str in x.id]


def match_device_by_sn(
        search_str: str, available_devices: Iterable[_T]
) -> List[_T]:

    return [x for x in available_devices if search_str == x.state.serial_number]


def match_unique_device_by_serial_number(
        search_str: str, available_devices: Iterable[_T]
) -> _T:
    matching_devices = match_device_by_sn(search_str, available_devices)
    assert len(matching_devices) == 1, f"There is {len(matching_devices)} serial number matching {search_str}"
    return matching_devices[0]


def match_unique_device_by_id(
        search_str: str, available_devices: Iterable[_T]
) -> _T:
    matching_devices = match_device_by_id(search_str, available_devices)
    if not matching_devices:
        available_devices_msg_str = format_available_devices_str(
            available_devices)
        raise MatchNotUniqueError((
            "No device dirname match specified "
            "search string: '{}'.\n\n{}"
        ).format(
            search_str,
            available_devices_msg_str
        ))

    matching_count = len(matching_devices)
    if matching_count > 1:
        matching_devices_msg_str = format_matching_devices_str(matching_devices)
        raise MatchNotUniqueError((
            "Too many dirname match for the specified "
            "search string: '{}'\n\n{}"
        ).format(
            search_str,
            matching_devices_msg_str
        ))

    assert matching_count == 1, f"There is {len(matching_count)} matching device id"
    return matching_devices[0]


def format_available_devices_str(
        devices: Iterable[DeviceInstanceWId]) -> str:
    devices_str = "\n".join(x.id for x in devices)
    available_devices_msg_str = (
        "Available devices\n"
        "------------------\n\n"
        "{}\n"
    ).format(devices_str)
    return available_devices_msg_str


def format_matching_devices_str(
        devices: Iterable[DeviceInstanceWId]) -> str:
    devices_str = "\n".join(x.id for x in devices)
    available_devices_msg_str = (
        "Matching devices\n"
        "----------------\n\n"
        "{}\n"
    ).format(devices_str)
    return available_devices_msg_str
