
from typing import List, Any, Dict, Tuple, Union


def sanitize_shell_out_to_line_list(
        shell_output: Union[bytes, str]
) -> List[str]:
    if isinstance(shell_output, bytes):
        shell_output = shell_output.decode("utf-8")
    return shell_output.rstrip().splitlines()


def _tuple_to_shell_opts(in_list: Tuple[Any, ...]) -> List[str]:
    out = []
    for v in in_list:
        # assert isinstance(v, str)
        out.append(str(v))
    return out


def _dict_to_shell_opts(in_dict: Dict[str, Any]) -> List[str]:
    out = []
    for k, v in in_dict.items():
        if 1 < len(k):
            out.append("--{}".format(k))
        else:
            out.append("-{}".format(k))

        if v is not None:
            # assert isinstance(v, str)
            out.append(str(v))

    return out
