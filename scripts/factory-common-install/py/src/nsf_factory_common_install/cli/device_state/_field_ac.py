"""A set of auto-completion tools.
"""
import os
from itertools import chain
from typing import Any, Set, List, Iterable, Dict, Optional
from nsf_factory_common_install.types_device import DeviceInstanceStateAccessError

from ._fields_schema import get_field_schema, list_known_field_names
from ._ctx import get_cli_ctx_db


def _get_set_of_mandatory_fields(ctx: Any) -> Set[str]:
    # TODO: A way to specify via context wheter the file override
    # another one so that we can infer when there is no mandatory
    # fields.
    return {
        "identifier",
        "type"
    }


def _get_set_of_ro_fields(ctx: Any) -> Set[str]:
    # TODO: A way to specify via context wheter the file override
    # another one so that we can infer when there is no mandatory
    # fields.
    return {
        "backend"
    }


def _get_ac_current_device_id(
        ctx: Any, args: List[str]) -> Optional[str]:
    device_id = None

    try:
        device_id = args[args.index("-d") + 1]
    except (ValueError, IndexError):
        pass

    if device_id is None:
        device_id = os.environ.get("NSF_CLI_DEFAULT_DEVICE_ID")

    return device_id


def _get_ac_current_device_state_d(
        ctx: Any, args: List[str]) -> Dict[str, Any]:
    device_id = _get_ac_current_device_id(ctx, args)

    db = get_cli_ctx_db(ctx)

    try:
        if device_id:
            device = db.get_device_instance(device_id)
            return device.state_plain
    except DeviceInstanceStateAccessError:
        pass

    try:
        current_device = db.get_current_device()
        if current_device is not None:
            return current_device.state_plain
    except DeviceInstanceStateAccessError:
        pass

    return {}


def _list_ac_current_device_field_names(
        ctx: Any, args: List[str]) -> Iterable:
    return _get_ac_current_device_state_d(ctx, args).keys()


def _list_ac_all_fields(ctx: Any, args: List[str]) -> Iterable[str]:
    known_fields = list_known_field_names()
    current_dev_fields = _list_ac_current_device_field_names(ctx, args)

    return sorted(
        set(chain(known_fields, current_dev_fields)))


def _match_ac_incomplete(
        candidates: Iterable[str], incomplete: str) -> List[str]:
    out = [fn for fn in candidates if fn.startswith(incomplete)]
    if not out:
        out = [fn for fn in candidates if incomplete in fn]

    return sorted(out)


def list_ac_editable_field_names(
        ctx: Any, args: List[str], incomplete: str
) -> List[Any]:  # Should have been: List[str]
    ro_set = _get_set_of_ro_fields(ctx)
    candidates = (
        f for f in _list_ac_all_fields(ctx, args)
        if f not in ro_set)

    return _match_ac_incomplete(candidates, incomplete)


def list_ac_readable_field_names(
        ctx: Any, args: List[str], incomplete: str
) -> List[Any]:  # Should have been: List[str]
    candidates = _list_ac_all_fields(ctx, args)
    return _match_ac_incomplete(candidates, incomplete)


def list_ac_removable_field_names(
        ctx: Any, args: List[str], incomplete: str
) -> List[Any]:  # Should have been: List[str]
    non_removable_set = _get_set_of_mandatory_fields(ctx)
    candidates = (
        f for f in _list_ac_all_fields(ctx, args)
        if f not in non_removable_set)

    return _match_ac_incomplete(
        candidates,
        incomplete
    )


def list_ac_field_values(
        ctx: Any, args: List[str], incomplete: str
) -> List[Any]:  # Should have been: List[str]
    field_name = args[-1]
    assert isinstance(field_name, str)

    db = get_cli_ctx_db(ctx)
    candidates = get_field_schema(field_name).list_choices(db)

    return _match_ac_incomplete(candidates, incomplete)
