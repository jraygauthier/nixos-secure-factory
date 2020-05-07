
def sanitize_bash_path_out(in_path: bytes):
    return in_path.decode("utf-8").strip()
