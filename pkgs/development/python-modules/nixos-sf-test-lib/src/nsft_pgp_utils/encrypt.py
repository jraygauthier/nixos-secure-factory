
from pathlib import Path
from typing import Optional, List, Iterable, Dict, Any
from dataclasses import dataclass

from .ctx_proc_types import OptGpgProcContextSoftT
from .process import run_gpg, run_precmd_and_pipe_to_gpg


@dataclass
class EncryptAdvOpts:
    yes: bool = True
    quiet: bool = True
    default_recipient: Optional[str] = None
    default_recipient_self: bool = False


OptEncryptAdvOpts = Optional[EncryptAdvOpts]


def _process_encrypt_adv_opts(
    out_args: List[str],
    opts: OptEncryptAdvOpts
):
    if opts is None:
        opts = EncryptAdvOpts()

    if opts.yes:
        out_args.append("--yes")

    if opts.quiet:
        out_args.append("--quiet")

    if opts.default_recipient is not None:
        out_args.extend(["--default-recipient", f"{opts.default_recipient}"])

    if opts.default_recipient_self:
        out_args.append("--default-recipient-self")


def _encrypt_to_gpg_file(
        out_file: Path,
        in_file: Optional[Path],
        in_text_content: Optional[Iterable[str]],
        recipients: Optional[Iterable[str]],
        pre_encode_to_b64: bool,
        adv_opts: OptEncryptAdvOpts,
        proc: OptGpgProcContextSoftT
) -> Path:
    if recipients is None:
        recipients = []

    args = [
        "--batch",
        "-e",
    ]

    _process_encrypt_adv_opts(args, adv_opts)

    for r in recipients:
        args.extend([
            "-r", f"{r}"
        ])

    args.extend([
        "-o", f"{out_file}"
    ])

    assert in_file is not None or in_text_content is not None

    if in_file is not None:
        assert in_text_content is None
        args.append(f"{in_file}")

    run_gpg_kwargs: Dict[str, Any] = {
        'check': True,
        'proc': proc
    }

    if in_text_content is not None:
        assert in_file is None
        run_gpg_kwargs['text'] = True
        run_gpg_kwargs['input'] = in_text_content

    if not pre_encode_to_b64:
        run_gpg(
            args, **run_gpg_kwargs)
        return out_file

    pre_cmd = "base64"
    pre_args: List[str] = []

    run_precmd_and_pipe_to_gpg(
        pre_cmd, pre_args, args, **run_gpg_kwargs)

    return out_file


def encrypt_file_to_gpg_file(
        in_file: Path,
        out_file: Path,
        recipients: Optional[Iterable[str]] = None,
        pre_encode_to_b64: bool = False,
        adv_opts: OptEncryptAdvOpts = None,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    return _encrypt_to_gpg_file(
        out_file,
        in_file,
        None,
        recipients,
        pre_encode_to_b64,
        adv_opts,
        proc
    )


def encrypt_text_content_to_gpg_file(
        in_content: Iterable[str],
        out_file: Path,
        recipients: Optional[Iterable[str]] = None,
        pre_encode_to_b64: bool = False,
        adv_opts: OptEncryptAdvOpts = None,
        proc: OptGpgProcContextSoftT = None
) -> Path:
    return _encrypt_to_gpg_file(
        out_file,
        None,
        in_content,
        recipients,
        pre_encode_to_b64,
        adv_opts,
        proc
    )
