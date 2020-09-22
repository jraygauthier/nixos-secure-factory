from pathlib import Path


def get_test_data_dir() -> Path:
    return Path(__name__).parent
