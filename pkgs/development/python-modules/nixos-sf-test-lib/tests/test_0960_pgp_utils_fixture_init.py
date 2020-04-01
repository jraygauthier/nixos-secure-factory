from _pytest.tmpdir import TempPathFactory
from pathlib import Path

from nsft_cache_utils.dir import PyTestFixtureRequestT
from nsft_pgp_utils.fixture_initial import (GpgInitialFixture,
                                            copy_gpg_initial_fixture)
from test_lib.gpg_ctx_fixture_gen import generate_gpg_initial_fixture_cached


def _check_initial_ok(fix: GpgInitialFixture) -> None:
    assert fix.i_ie.proc.home_dir.exists()
    assert 1 == len(fix.i_ie.keys.secret)
    # The encrypter knows about all of its targets.
    assert 5 == len(fix.i_ie.keys.public)

    assert not fix.i_z.proc.home_dir.exists()
    assert 0 == len(fix.i_z.keys.all)

    assert fix.i_m.proc.home_dir.exists()
    assert 0 == len(fix.i_m.keys.all)

    assert fix.i_s.proc.home_dir.exists()
    assert 0 == len(fix.i_s.keys.public)
    assert 1 == len(fix.i_s.keys.secret)

    assert fix.i_f.proc.home_dir.exists()
    assert 0 == len(fix.i_f.keys.public)
    assert 2 == len(fix.i_f.keys.secret)
    assert fix.i_f.keys.secret[0].info.email != fix.i_f.keys.secret[1].info.email

    assert fix.i_t.proc.home_dir.exists()
    assert 0 == len(fix.i_t.keys.public)
    assert 2 == len(fix.i_t.keys.secret)
    assert fix.i_t.keys.secret[0].info.email == fix.i_t.keys.secret[1].info.email


def test_generate_initial_fixture(
        request: PyTestFixtureRequestT,
        tmp_root_homes_dir: Path) -> None:
    # from test_lib.gpg_ctx_fixture_gen import generate_gpg_initial_fixture
    # fix = generate_gpg_initial_fixture(tmp_root_homes_dir)
    fix = generate_gpg_initial_fixture_cached(
        tmp_root_homes_dir, request)

    _check_initial_ok(fix)


def test_copy_initial_fixture(
        tmp_path_factory: TempPathFactory,
        gpg_initial: GpgInitialFixture) -> None:

    copied_root_homes_dir = tmp_path_factory.mktemp("root_homes-copied")

    copied_fix = copy_gpg_initial_fixture(copied_root_homes_dir, gpg_initial)
    _check_initial_ok(copied_fix)
