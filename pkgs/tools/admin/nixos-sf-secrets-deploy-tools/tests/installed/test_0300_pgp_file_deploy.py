import logging
import os
import subprocess
import pytest

from pathlib import Path

from nsft_shell_utils.outcome import (
    ExpShOutcomeByCtxSoftT,
    ExpShOutcome,
    ensure_exp_shell_outcome_by_context,
    check_sh_output_is_empty
)


from nsft_system_utils.file import read_text_file_content
from nsft_shell_utils.program import call_shell_program
from nsft_system_utils.permissions import (
    FilePermissions,
    change_file_permissions,
    ensure_file_permissions_opt,
    ensure_file_permissions_w_ref,
    format_file_permission,
    get_file_permissions,
    FilePermissionsOptsSoftT
)

from test_lib.env import (
    are_package_propagated_dependencies_installed,
    from_nixos_test_machine,
    is_package_installed,
)

from test_lib.gpg_ctx_fixture_gen import GpgEncryptDecryptBasicFixture

LOGGER = logging.getLogger(__name__)


# pytestmark = pytest.mark.skipif(
#   not is_package_installed(),
#   reason="Package programs not found in PATH!")

mark_only_for_nixos_test_machine = pytest.mark.skipif(
    not from_nixos_test_machine(),
    reason="Only reproducible on controlled test machine."
)


def test_package_installed():
    assert is_package_installed()


def test_propagated_dependencies_installed():
    assert are_package_propagated_dependencies_installed()


def test_get_sh_lib_dir():
    lines = call_shell_program("pkg-nixos-sf-secrets-deploy-tools-get-sh-lib-dir")
    assert lines
    dir_path = lines[0]
    assert os.path.exists(dir_path)

    sh_module_path = os.path.join(dir_path, "deploy-tools.sh")
    assert os.path.exists(sh_module_path)


def get_current_ctx_outcome(
        expected_outcome: ExpShOutcomeByCtxSoftT) -> ExpShOutcome:
    exp_outcome = ensure_exp_shell_outcome_by_context(expected_outcome)
    if from_nixos_test_machine():
        return exp_outcome.privileged
    else:
        return exp_outcome.unprivileged


def check_has_expected_permissions(
        in_file: Path, expected: FilePermissions) -> None:
    actual = get_file_permissions(in_file)
    assert expected.mode_simple == actual.mode_simple
    assert expected.uid == actual.uid
    assert expected.gid == actual.gid


_decrypt_invalid_file_exp_outcome = (
    1, [r"gpg"], [
        r"gpg",
        r"no valid OpenPGP data found", r"decrypt_message failed",
        r"Unknown system error"]
)

_decrypt_invalid_file_b64_side_exp_outcome = (
    1, [r"gpg"], [
        r"base64",
        r"invalid input"]
)

_decrypt_invalid_file_is_dir_exp_outcome = (
    1, [r"gpg"], [
        r"gpg",
        r"read error", r"decrypt_message failed",
        r"Unknown system error"]
)

_decrypt_happy_exp_outcome = (
    0, [r"gpg", r"chmod", r"chown"], check_sh_output_is_empty
)


@pytest.mark.parametrize(
    "rel_src_file, rel_tgt_file, exp_outcome_by_ctx, inh_permissions", [
        # Check that we fail as expected when source extension is wrong.
        ("original/file.txt", "decrypted.txt", ((
            1, check_sh_output_is_empty, [
                r"unexpected last extension 'txt'",
                r"Expected 'gpg'"]),),
            None),
        # Check that simple happy case works fine. It validates in particular
        # that format autodetection via extensions works fine.
        ("encrypted-r-all/file.txt.b64.gpg", "decrypted.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        ("encrypted-r-all/file.txt.gpg", "decrypted.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        # Check that we fail as expected when src does not exists.
        ("encrypted-r-all/does-not-exist.txt.b64.gpg", "decrypted.txt", ((
            1, [r"gpg"], [
                r"gpg",
                r"does-not-exist.txt.b64.gpg",
                r"No such file or directory",
                r"decrypt_message failed"]),),
            None),
        ("encrypted-r-all/does-not-exist.txt.gpg", "decrypted.txt", ((
            1, [r"gpg"], [
                r"gpg",
                r"does-not-exist.txt.gpg",
                r"No such file or directory",
                r"decrypt_message failed"]),),
            None),
        # Check that we behave as expected when target already exists.
        ("encrypted-r-all/file.txt.b64.gpg", "dummy.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        ("encrypted-r-all/file.txt.gpg", "dummy-ro.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        # Check that we behave as expected when the secrets is encrypted
        # with only us (a) as a recipient.
        ("encrypted-r-a/file.txt.b64.gpg", "dummy.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        ("encrypted-r-a/file.txt.gpg", "dummy-ro.txt", (
            _decrypt_happy_exp_outcome,),
            None),
        # Check that we fail as expected
        # when the src secrets is not encrypted with us (a) as a recipient
        # but is meant to another (b).
        # Also check (see below code) that existing target remain untouched
        # when an error occur.
        ("encrypted-r-b/file.txt.b64.gpg", "dummy.txt", ((
            1, [r"gpg"], [r"decryption failed", r"No secret key"]),),
            None),
        ("encrypted-r-b/file.txt.gpg", "dummy-ro.txt", ((
            1, [r"gpg"], [r"decryption failed", r"No secret key"]),),
            None),
        # Check all kind of files/directories that are not what they pretend to
        # via their extensions.
        ("encrypted-r-all/fraud-txt-file-as.txt.gpg", "decrypted.txt", (
            _decrypt_invalid_file_exp_outcome,),
            None),
        ("encrypted-r-all/fraud-txt-file-as.txt.b64.gpg", "decrypted.txt", (
            _decrypt_invalid_file_exp_outcome,),
            None),
        ("encrypted-r-all/fraud-txt-gpg-file-as.txt.b64.gpg", "decrypted.txt", (
            _decrypt_invalid_file_b64_side_exp_outcome,),
            None),
        # WARNING: This one is a weak spot. We are unable to reliably detect that
        # the output is not the original secret but instead a base 64 copy.
        pytest.param(
            "encrypted-r-all/fraud-txt-b64-gpg-file-as.txt.gpg", "decrypted.txt", (
                _decrypt_happy_exp_outcome,),
            None,
            marks=pytest.mark.xfail(
                raises=AssertionError,
                reason="Deployed base64 content instead of original secret.")),
        ("encrypted-r-all/fraud-dir-as.txt.gpg", "decrypted.txt", (
            _decrypt_invalid_file_is_dir_exp_outcome,),
            None),
        ("encrypted-r-all/fraud-dir-as.txt.b64.gpg", "decrypted.txt", (
            _decrypt_invalid_file_is_dir_exp_outcome,),
            None),

        # ("encrypted-r-all/file-txt-b64-gpg-no-ext"
        # ("encrypted-r-all/file-txt-gpg-no-ext"
    ])
def test_pgp_file_deploy_w_inherited_permissions(
        gpg_encrypt_decrypt_basic_ro: GpgEncryptDecryptBasicFixture,
        src_pgp_decrypt_dir: Path, tgt_pgp_decrypt_dir: Path,
        rel_src_file: str, rel_tgt_file: str,
        exp_outcome_by_ctx: ExpShOutcomeByCtxSoftT,
        inh_permissions: FilePermissionsOptsSoftT) -> None:
    fix = gpg_encrypt_decrypt_basic_ro
    exp_outcome = get_current_ctx_outcome(exp_outcome_by_ctx)
    inh_permissions = ensure_file_permissions_opt(inh_permissions)

    src_tmp_dir = src_pgp_decrypt_dir
    src_file = src_tmp_dir.joinpath(rel_src_file)

    ori_file_content = read_text_file_content(src_tmp_dir.joinpath("original/file.txt"))

    tgt_tmp_dir = tgt_pgp_decrypt_dir
    tgt_file = tgt_tmp_dir.joinpath(rel_tgt_file)

    tgt_file_original_content = None
    if tgt_file.exists():
        tgt_file_original_content = read_text_file_content(tgt_file)

    LOGGER.info("src_file: %s", src_file)
    LOGGER.info("tgt_file: %s", tgt_file)

    change_file_permissions(tgt_tmp_dir, inh_permissions)

    LOGGER.info("tgt_tmp_dir permissions: {%s}", format_file_permission(tgt_tmp_dir))

    exp_permissions = ensure_file_permissions_w_ref(inh_permissions, tgt_tmp_dir)

    def call_program():
        gpghomedir = fix.d_a.proc.home_dir
        LOGGER.info(f"export GNUPGHOME={gpghomedir}")
        env = {}
        env.update(os.environ)
        env.update({
            'GNUPGHOME': f"{gpghomedir}"
        })

        return subprocess.run(
            [
                "nsf-pgp-file-deploy-w-inherited-permissions",
                src_file,
                tgt_file
            ],
            check=True, text=True,
            stdout=(None if exp_outcome.stdout.no_expects() else subprocess.PIPE),
            stderr=(None if exp_outcome.stderr.no_expects() else subprocess.PIPE),
            env=env
        )

    if not exp_outcome.success():
        with pytest.raises(subprocess.CalledProcessError) as e:
            call_program()

        exp_outcome.check_expected_error(e.value)

        if tgt_file_original_content is None:
            # When there was no original file, there should still be no file on
            # error.
            assert not os.path.exists(tgt_file)
        else:
            # When an original file was present, it should still be there and
            # its content unchanged.
            assert os.path.exists(tgt_file)
            tgt_file_content = read_text_file_content(tgt_file)
            assert tgt_file_original_content == tgt_file_content

        return

    call_program()

    assert os.path.exists(tgt_file)

    tgt_file_content = read_text_file_content(tgt_file)
    assert ori_file_content == tgt_file_content

    LOGGER.info("tgt_file permissions: {%s}", format_file_permission(tgt_file))

    check_has_expected_permissions(tgt_file, exp_permissions)
