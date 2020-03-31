import os
import time
import shutil
import hashlib
import logging

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional, Callable, List, Set, TypeVar

from nsft_system_utils.file import write_text_file_content, touch_file

try:
    from _pytest.fixtures import FixtureRequest as _FixtureRequestT
    _with_pytest = True
except ModuleNotFoundError:
    _FixtureRequestT = Any
    _with_pytest = False


PyTestFixtureRequestT = _FixtureRequestT
OptPyTestFixtureRequestT = Optional[_FixtureRequestT]


OptCopyIgnoreFnT = Optional[Callable[[str, List[str]], Set[str]]]


@dataclass
class CacheDirState:
    path: Optional[Path]
    valid: bool


class ICacheDirProvider(ABC):
    @abstractmethod
    def mk_cache_dir(
            self, module_filename: Path, cache_id: str
    ) -> CacheDirState:
        pass


OptICacheDirProvider = Optional[ICacheDirProvider]


def _mk_unique_cache_str_for(module_filename: Path, cache_id: str) -> str:
    # Some program such as gpg do not work well with long files names.
    # Using a short hash of what would have been the dir name fixes
    # those cases.
    composed_str = f"nsft-{module_filename}-{cache_id}"
    hashed_str = \
        hashlib.sha256(composed_str.encode()).hexdigest()[0:12]
    return hashed_str


class DefaultCacheDirProvider(ICacheDirProvider):
    def mk_cache_dir(
            self, module_filename: Path, cache_id: str) -> CacheDirState:
        module_dir = Path(module_filename).parent
        unique_hashed_str = _mk_unique_cache_str_for(module_filename, cache_id)
        cache_dir = module_dir.joinpath(
            "__pycache__", "nsft", unique_hashed_str)
        cache_dir_exists = cache_dir.exists()
        return CacheDirState(path=cache_dir, valid=cache_dir_exists)


class DisabledCacheDirProvider(ICacheDirProvider):
    def mk_cache_dir(
            self, module_filename: Path, cache_id: str) -> CacheDirState:
        return CacheDirState(path=None, valid=False)


def obtain_cache_dir(
        module_filename: Path,
        cache_id: str,
        stale_after_s: Optional[float] = None,
        cache_dir_provider: OptICacheDirProvider = None
) -> CacheDirState:
    if stale_after_s is None:
        # Defaults to 30 minutes.
        stale_after_s = 60 * 30

    if cache_dir_provider is None:
        cache_dir_provider = DefaultCacheDirProvider()

    prov_dir_state = cache_dir_provider.mk_cache_dir(module_filename, cache_id)

    if prov_dir_state.path is None:
        assert not prov_dir_state.valid
        # No possible cache for unknown reason. Caching might be disabled or
        # file system used by the cache provider read-only.
        return CacheDirState(path=None, valid=False)

    cache_dir = prov_dir_state.path
    cache_dir_exists = prov_dir_state.valid
    cache_last_accessed_token = cache_dir.joinpath(".nsft-cache-last-accessed-token")

    try:
        cache_dir.mkdir(parents=True, exist_ok=True)
        touch_file(cache_last_accessed_token)
    except OSError as e:
        if 30 != e.errno:
            raise  # re-raise.

        # Read-only file system. No possible cache.
        return CacheDirState(path=None, valid=False)

    if not cache_dir_exists:
        cache_last_accessed_token.unlink()
        return CacheDirState(path=cache_dir, valid=False)

    cache_mtime_s = os.stat(cache_dir).st_mtime
    cache_stale_s = cache_mtime_s + stale_after_s
    current_time_s = time.time()
    assert cache_mtime_s <= current_time_s
    if current_time_s < cache_stale_s:
        return CacheDirState(path=cache_dir, valid=True)

    # Stale cache. Recreate.
    shutil.rmtree(cache_dir)
    cache_dir.mkdir()
    return CacheDirState(path=cache_dir, valid=False)


def copy_ignore_gpg_home_dir(src, names):
    logging.warning(f"src: {src}, names: {names}")
    return names


_LoadDirContentRetT = TypeVar('_LoadDirContentRetT')


def create_dir_content_cached(
        module_filename: Path,
        dir: Path,
        generate_dir_content_fn: Callable[[Path], _LoadDirContentRetT],
        stale_after_s: Optional[float] = None,
        cache_dir_provider: OptICacheDirProvider = None,
        copy_ignore_fn: OptCopyIgnoreFnT = None,
        load_dir_content_fn: Optional[Callable[[Path], _LoadDirContentRetT]] = None,
) -> _LoadDirContentRetT:
    def default_load_dir_content(in_path: Path) -> _LoadDirContentRetT:
        pass

    if load_dir_content_fn is None:
        load_dir_content_fn = default_load_dir_content

    cache_id = generate_dir_content_fn.__name__

    cache_state = obtain_cache_dir(
        module_filename,
        generate_dir_content_fn.__name__,
        stale_after_s=stale_after_s,
        cache_dir_provider=cache_dir_provider
    )

    if cache_state.valid:
        assert cache_state.path is not None
        shutil.rmtree(dir)
        shutil.copytree(cache_state.path, dir, ignore=copy_ignore_fn)
        return load_dir_content_fn(dir)

    if cache_state.path is None:
        return generate_dir_content_fn(dir)

    generate_dir_content_fn(cache_state.path)

    # Write some info about what module / function gave rise to this cache.
    cache_info = cache_state.path.joinpath(".nsft-cache-info")
    write_text_file_content(
        cache_info, [
            f"{module_filename}::{cache_id}"]
    )

    shutil.rmtree(dir)
    shutil.copytree(cache_state.path, dir, ignore=copy_ignore_fn)
    return load_dir_content_fn(dir)


# There is not much I can do to fix complexity here as indent
# is artificial.
if _with_pytest:  # noqa C901
    class PyTestCacheDirProvider(ICacheDirProvider):
        def __init__(self, request: _FixtureRequestT) -> None:
            self._request = request

        def _mk_pytest_cache_dir(
                self, cache_key: str, hashed_dir_name: str) -> Optional[Path]:

            try:
                # Some program such as gpg do not work well with long files names.
                # Using a short hash of what would have been the dir name fixes
                # those cases.
                cache_dir_str = str(self._request.config.cache.makedir(
                    hashed_dir_name))
            except OSError as e:
                if 30 != e.errno:
                    raise  # re-raise

                # Read-only file-system.
                return None

            cache_dir = Path(cache_dir_str)
            assert cache_dir.exists()

            self._request.config.cache.set(cache_key, str(cache_dir))
            return cache_dir

        def mk_cache_dir(
                self, module_filename: Path, cache_id: str) -> CacheDirState:
            module_name = module_filename.stem

            unique_hashed_str = \
                _mk_unique_cache_str_for(module_filename, cache_id)

            cache_key = f"nsft-cache/{module_name}/{cache_id}/{unique_hashed_str}"
            existing_cache_dir_str = self._request.config.cache.get(cache_key, None)

            cache_dir = None
            if existing_cache_dir_str is not None:
                cache_dir = Path(existing_cache_dir_str)
                if cache_dir.exists():
                    return CacheDirState(path=cache_dir, valid=True)

            hashed_dir_name = f"nsft-{unique_hashed_str}"
            cache_dir = self._mk_pytest_cache_dir(cache_key, hashed_dir_name)
            return CacheDirState(path=cache_dir, valid=False)

    def create_dir_content_cached_from_pytest(
            module_filename: Path,
            dir: Path,
            generate_dir_content_fn: Callable[[Path], _LoadDirContentRetT],
            request: Optional[_FixtureRequestT],
            stale_after_s: Optional[float] = None,
            copy_ignore_fn: OptCopyIgnoreFnT = None,
            load_dir_content_fn: Optional[Callable[[Path], _LoadDirContentRetT]] = None,
    ) -> _LoadDirContentRetT:
        if request is None:
            cache_dir_provider = None
        else:
            cache_dir_provider = PyTestCacheDirProvider(request)

        return create_dir_content_cached(
            module_filename,
            dir,
            generate_dir_content_fn,
            stale_after_s,
            cache_dir_provider,
            copy_ignore_fn,
            load_dir_content_fn)
