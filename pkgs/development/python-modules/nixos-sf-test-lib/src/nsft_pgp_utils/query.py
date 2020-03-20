from typing import Iterator, List

from ._colon_listing_impl import _list_gpg_keys_w_ext_info_it
from ._export_impl import _export_gpg_otrust_to_str
from ._file_formats_impl import _parse_otrust_content_it
from .ctx_auth_types import OptGpgAuthContext, ensure_gpg_auth_ctx
from .ctx_types import GpgContextKeysWExtInfo, GpgContextWExtInfo
from .key_types import (
    GpgKeyExtInfoWOTrust,
    GpgKeyWEmail,
    GpgKeyWExtInfo,
    GpgKeyWExtInfoWOTrust,
    GpgKeyWTrust,
)
from .trust_types import GpgTrust
from .process import OptGpgProcContextSoftT, ensure_gpg_proc_ctx, gpg_stdout_it


def _list_gpg_keys_lines_it(
        secret: bool = False,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> Iterator[str]:
    args = [
        "--list-options", "show-only-fpr-mbox",
    ]

    if secret:
        args.append("--list-secret-keys")
    else:
        args.append("--list-keys")

    yield from gpg_stdout_it(
        args, proc=proc, auth=auth)


def list_gpg_keys_it(
        secret: bool = False,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWEmail]:
    for l in _list_gpg_keys_lines_it(
            secret, auth, proc):
        splits = list(map(str.strip, l.split(' ')))
        yield GpgKeyWEmail(splits[0], splits[1])


def list_gpg_keys(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(False, auth, proc))


def list_gpg_secret_keys(
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None
) -> List[GpgKeyWEmail]:
    return list(list_gpg_keys_it(True, auth, proc))


def list_gpg_ownertrust(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None) -> List[GpgKeyWTrust]:
    content_str = _export_gpg_otrust_to_str(auth=auth, proc=proc)
    return list(_parse_otrust_content_it(content_str))


def list_gpg_keys_w_ext_info(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> List[GpgKeyWExtInfo]:
    return list(_list_gpg_keys_w_ext_info_it(False, auth, proc))


def list_gpg_secret_keys_w_ext_info(
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> List[GpgKeyWExtInfo]:
    return list(_list_gpg_keys_w_ext_info_it(True, auth, proc))


def query_gpg_context_keys_w_ext_info(
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None) -> GpgContextKeysWExtInfo:

    skeys = list_gpg_secret_keys_w_ext_info(auth, proc)
    keys = list_gpg_keys_w_ext_info(auth, proc)
    otrust = list_gpg_ownertrust(auth, proc)

    skey_fpr_set = set()
    for sk in skeys:
        skey_fpr_set.add(sk.fpr)

    pkeys = []
    for k in keys:
        if k.fpr in skey_fpr_set:
            continue

        pkeys.append(k)

    otrust_d = {}
    for ot in otrust:
        otrust_d[ot.fpr] = ot.trust

    def combine_keys_with_otrust(
            in_keys: List[GpgKeyWExtInfo]
    ) -> List[GpgKeyWExtInfoWOTrust]:
        out_keys = []
        for ik in in_keys:
            # TODO: Unsure if this is the appropriate value.
            otrust = otrust_d.get(ik.fpr, GpgTrust.TrustUnknown)
            out_keys.append(GpgKeyWExtInfoWOTrust(ik.fpr, GpgKeyExtInfoWOTrust(
                otrust=otrust,
                **ik.info.__dict__
            )))
        return out_keys

    pkeys_w_ot = combine_keys_with_otrust(pkeys)
    skeys_w_ot = combine_keys_with_otrust(skeys)

    return GpgContextKeysWExtInfo(
        public=pkeys_w_ot,
        secret=skeys_w_ot
    )


def query_gpg_context_w_ext_info(
        auth: OptGpgAuthContext,
        proc: OptGpgProcContextSoftT = None) -> GpgContextWExtInfo:
    keys = query_gpg_context_keys_w_ext_info(auth, proc)
    return GpgContextWExtInfo(
        proc=ensure_gpg_proc_ctx(proc),
        auth=ensure_gpg_auth_ctx(auth),
        keys=keys)
