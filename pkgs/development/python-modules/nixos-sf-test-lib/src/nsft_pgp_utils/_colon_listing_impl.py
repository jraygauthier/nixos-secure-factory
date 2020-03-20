from typing import Iterator, Dict, List, Union, Optional, Any

from .ctx_auth_types import OptGpgAuthContext
from .ctx_proc_types import OptGpgProcContextSoftT
from .key_types import GpgKeyWExtInfo, GpgKeyExtInfo
from .process import gpg_stdout_it

from .trust_types import mk_gpg_calc_trust_from_colon_sep_field_value

GpgKeyWithColonSubKeyEntryDictT = Dict[str, str]
GpgKeyWithColonSubKeyEntriesListT = List[GpgKeyWithColonSubKeyEntryDictT]
GpgKeyWithColonEntryDictT = Dict[str, Union[str, GpgKeyWithColonSubKeyEntriesListT]]


class GpgKeyWithColonParsingError(Exception):
    pass


def _list_gpg_keys_with_colon_lines_it(
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

    args.append("--with-colons")

    yield from gpg_stdout_it(
        args, proc=proc, auth=auth)


def _list_gpg_keys_with_colon_records_it(  # noqa C901
        secret: bool = False,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWithColonEntryDictT]:
    out_rec: Optional[GpgKeyWithColonEntryDictT] = None
    line_it = _list_gpg_keys_with_colon_lines_it(
        secret, auth, proc)

    record_type = "sec" if secret else "pub"
    sub_record_type = "ssb" if secret else "sub"
    subs_record_key = "ssbs" if secret else "subs"

    for l in line_it:
        ft = l[0:3]  # Field type.
        if "tru" == ft:
            continue
        if record_type == ft:
            if out_rec is not None:
                yield out_rec

            out_rec = {
                ft: l
            }
            continue
        if out_rec is None:
            continue

        if sub_record_type == ft:
            subs = out_rec.setdefault(subs_record_key, list())
            assert isinstance(subs, list)
            subs.append({
                ft: l
            })
            continue

        tgt_rec: Dict[str, Any] = out_rec
        try:
            subs = out_rec[subs_record_key]
            assert isinstance(subs, list)
            tgt_rec = subs[-1]
        except KeyError:
            pass

        if ft in tgt_rec:
            raise GpgKeyWithColonParsingError(f"Unexpected duplicate field type: {ft}.")

        tgt_rec.setdefault(ft, l)

    if out_rec is not None:
        yield out_rec


def _list_gpg_keys_w_ext_info_it(
        secret: bool = False,
        auth: OptGpgAuthContext = None,
        proc: OptGpgProcContextSoftT = None
) -> Iterator[GpgKeyWExtInfo]:
    record_type = "sec" if secret else "pub"

    for d in _list_gpg_keys_with_colon_records_it(secret, auth, proc):
        fpr_l = d["fpr"]
        assert isinstance(fpr_l, str)
        fpr_field = fpr_l.split(':')[9]
        fpr_field = fpr_field.strip()

        uid_l = d["uid"]
        assert isinstance(uid_l, str)
        fn_eml_field = uid_l.split(':')[9]
        fn, eml = fn_eml_field.split("<")
        fn = fn.strip()
        eml = eml.strip().rstrip(">")

        entry_l = d[record_type]
        assert isinstance(entry_l, str)
        trust_field = entry_l.split(":")[1].strip()
        trust = mk_gpg_calc_trust_from_colon_sep_field_value(trust_field)
        yield GpgKeyWExtInfo(
            fpr=fpr_field,
            info=GpgKeyExtInfo(
                email=eml,
                user_name=fn,
                trust=trust
            )
        )
