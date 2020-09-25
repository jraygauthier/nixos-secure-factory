"""A set of commonly used click autocompletion helpers."""
from typing import List, Any
from ._device_set import match_device_by_id
from ._ctx import get_cli_ctx_db_w_device_list


def list_ac_available_device_ids(
        ctx: Any, args: List[str], incomplete: str
) -> List[Any]:  # Should have been: List[str]
    db = get_cli_ctx_db_w_device_list(ctx)

    return [d.id for d in match_device_by_id(
        incomplete,
        db.list_device_instances()
    )]
