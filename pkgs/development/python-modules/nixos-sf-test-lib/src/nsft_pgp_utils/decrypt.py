
import subprocess
from pathlib import Path
from typing import Optional, Union, List, Dict, Any
from dataclasses import dataclass

from .process import run_gpg, run_gpg_and_pipe_to_postcmd
from .ctx_proc_types import OptGpgProcContextSoftT
from .ctx_auth_types import OptGpgAuthContext

_DecryptedT = Union[Path, List[str]]


@dataclass
class DecryptAdvOpts:
    yes: bool = True
    quiet: bool = True
    no_pinentry_ui: bool = True


OptDecryptAdvOpts = Optional[DecryptAdvOpts]


def _process_decrypt_adv_opts(
    out_args: List[str],
    opts: OptDecryptAdvOpts
):
    if opts is None:
        opts = DecryptAdvOpts()

    if opts.no_pinentry_ui:
        out_args.extend(["--pinentry-mode", "loopback"])

    if opts.yes:
        out_args.append("--yes")

    if opts.quiet:
        out_args.append("--quiet")


def _process_decrypt_output(
    completed_p: subprocess.CompletedProcess,
    out_file: Optional[Path],
    out_as_text_str: bool,
) -> _DecryptedT:
    if out_file is not None:
        assert not out_as_text_str
        assert completed_p.stdout is None
        return out_file

    assert out_as_text_str
    assert completed_p.stdout is not None
    assert isinstance(completed_p.stdout, str)
    return completed_p.stdout.splitlines()


def _decrypt_from_gpg_file(
        in_file: Path,
        out_file: Optional[Path],
        out_as_text_str: bool,
        post_decode_from_b64: bool,
        adv_opts: OptDecryptAdvOpts,
        proc: OptGpgProcContextSoftT,
        auth: OptGpgAuthContext,
) -> _DecryptedT:
    args = [
        "--batch",
        "-d",
    ]

    _process_decrypt_adv_opts(args, adv_opts)

    assert out_file is not None or out_as_text_str

    in_file_args = [
        f"{in_file}"
    ]

    run_gpg_kwargs: Dict[str, Any] = {
        'check': True,
        'proc': proc,
        'auth': auth
    }

    if not post_decode_from_b64:
        out_kwargs: Dict[str, Any] = dict()

        if out_as_text_str:
            out_kwargs['text'] = True
            out_kwargs['stdout'] = subprocess.PIPE

        run_gpg_kwargs.update(out_kwargs)

        if out_file is not None:
            assert not out_as_text_str
            args.extend([
                "-o", f"{out_file}",
            ])

        args.extend(in_file_args)
        compl_p = run_gpg(
            args, **run_gpg_kwargs)
        return _process_decrypt_output(
            compl_p, out_file, out_as_text_str)

    post_cmd = "base64"
    post_args = ["-d"]

    args.extend(in_file_args)

    if out_file is not None:
        assert not out_as_text_str

        with open(out_file, "wb") as of:
            out_kwargs = {
                'stdout': of
            }
            compl_p = run_gpg_and_pipe_to_postcmd(
                post_cmd, post_args, out_kwargs,
                args, None, **run_gpg_kwargs)
    else:
        if out_as_text_str:
            out_kwargs = {
                'text': True,
                'stdout': subprocess.PIPE
            }

        compl_p = run_gpg_and_pipe_to_postcmd(
            post_cmd, post_args, out_kwargs,
            args, None, **run_gpg_kwargs)

    return _process_decrypt_output(
        compl_p, out_file, out_as_text_str)


def decrypt_gpg_file_to_file(
        in_file: Path,
        out_file: Path,
        post_decode_from_b64: bool = False,
        adv_opts: OptDecryptAdvOpts = None,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
) -> Path:
    out = _decrypt_from_gpg_file(
        in_file,
        out_file,
        False,
        post_decode_from_b64,
        adv_opts,
        proc,
        auth
    )
    assert isinstance(out, Path)
    return out


def decrypt_gpg_file_to_text_content(
        in_file: Path,
        post_decode_from_b64: bool = False,
        adv_opts: OptDecryptAdvOpts = None,
        proc: OptGpgProcContextSoftT = None,
        auth: OptGpgAuthContext = None,
) -> List[str]:
    out = _decrypt_from_gpg_file(
        in_file,
        None,
        True,
        post_decode_from_b64,
        adv_opts,
        proc,
        auth
    )
    assert isinstance(out, list)
    return out
