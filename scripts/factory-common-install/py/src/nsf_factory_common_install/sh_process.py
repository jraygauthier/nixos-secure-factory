import subprocess
from pathlib import Path


def sanitize_bash_path_out(in_path: bytes) -> Path:
    return Path(in_path.decode("utf-8").strip())


def collect_process_stdout(process_name: str, *args, **kwargs) -> Path:
    cmd_w_args = [process_name]
    cmd_w_args.extend(args)
    return sanitize_bash_path_out(subprocess.check_output(cmd_w_args, **kwargs))
