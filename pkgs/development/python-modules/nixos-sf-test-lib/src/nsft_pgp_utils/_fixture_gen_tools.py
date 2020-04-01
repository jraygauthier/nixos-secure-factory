from typing import Iterable
from .ctx_types import GpgContextWExtInfo, GpgContext
from .io_export import export_gpg_public_key_to_text
from .io_import import import_gpg_key_text
from .trust import sign_and_trust_gpg_key, GpgOwnerTrust


def import_pub_key_for_all_sids_in_ctxs(
        out_ctx: GpgContext, in_ctxs: Iterable[GpgContextWExtInfo]) -> None:
    for in_ctx in in_ctxs:
        for sk in in_ctx.keys.secret:
            exp_str = export_gpg_public_key_to_text(
                sk.fpr, **in_ctx.as_proc_auth_dict())
            import_gpg_key_text(exp_str, **out_ctx.as_proc_dict())
            # The following is essential as otherwise, file encyption will fail
            # with this key as a recipient.
            sign_and_trust_gpg_key(
                sk.fpr, GpgOwnerTrust.Fully,
                **out_ctx.as_proc_auth_dict())
