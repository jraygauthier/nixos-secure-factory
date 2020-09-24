import logging
from typing import Optional

from nsf_factory_common_install.store_factory_info import \
    get_factory_info_user_id

LOGGER = logging.getLogger(__name__)


def get_user_id() -> Optional[str]:
    try:
        return get_factory_info_user_id()
    except FileNotFoundError as e:
        LOGGER.warning(f"Cannot infer 'user_id': {str(e)}.")
        return None
