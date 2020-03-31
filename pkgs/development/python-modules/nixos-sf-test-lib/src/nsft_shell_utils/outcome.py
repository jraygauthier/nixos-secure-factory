import re
import subprocess
from dataclasses import dataclass, field
from typing import Tuple, Union, Iterable, Callable, Optional


class UnexpectedShStatusError(Exception):
    pass


ExpShStatusCheckFnOutT = Optional[UnexpectedShStatusError]
ExpShStatusCheckFnT = Callable[[int], ExpShStatusCheckFnOutT]


class UnexpectedShOutputError(Exception):
    pass


ExpShOutputCheckFnOutT = Optional[UnexpectedShOutputError]
ExpShOutputCheckFnT = Callable[[str], ExpShOutputCheckFnOutT]


class UnexpectedShOutcomeError(Exception):
    pass


class UnexpectedStatusShOutcomeError(UnexpectedShOutcomeError):
    pass


class UnexpectedStdOutShOutcomeError(UnexpectedShOutcomeError):
    pass


class UnexpectedStdErrShOutcomeError(UnexpectedShOutcomeError):
    pass


def check_sh_status_success(val: int) -> ExpShStatusCheckFnOutT:
    if 0 == val:
        return None

    return UnexpectedShStatusError(
        "Expected successfull shell call (status == 0). "
        f"Status was instead '{val}'."
    )


@dataclass
class ExpShStatus:
    check_fn: Optional[ExpShStatusCheckFnT]

    def success(self) -> bool:
        return self.check_fn is None \
            or self.check_fn is check_sh_status_success

    def no_expects(self) -> bool:
        return self.check_fn is None

    def has_expects(self) -> bool:
        return not self.no_expects()

    def check_as_expected(self, status: int) -> None:
        if self.check_fn is None:
            return

        error = self.check_fn(status)
        if error is not None:
            assert isinstance(error, UnexpectedShStatusError)
            raise error


ExpShStatusSoftT = Union[None, int, ExpShStatusCheckFnT, ExpShStatus]


def mk_exp_sh_status_success() -> ExpShStatus:
    return ExpShStatus(check_sh_status_success)


def mk_no_exp_sh_status() -> ExpShStatus:
    return ExpShStatus(check_fn=None)


def mk_exp_sh_status_equal_to(expected: int) -> ExpShStatus:
    if 0 == expected:
        return mk_exp_sh_status_success()

    def check(val: int) -> ExpShStatusCheckFnOutT:
        if val == expected:
            return None

        return UnexpectedShStatusError(
            f"Expected '{expected}' shell status. Status was instead '{val}'.")

    return ExpShStatus(check)


def ensure_exp_sh_status(val: ExpShStatusSoftT) -> ExpShStatus:
    if val is None:
        return mk_no_exp_sh_status()
    if isinstance(val, int):
        return mk_exp_sh_status_equal_to(val)

    if callable(val):
        return ExpShStatus(val)

    assert isinstance(val, ExpShStatus)
    return val


@dataclass
class ExpShOutput:
    check_fns: Iterable[ExpShOutputCheckFnT]

    def no_expects(self) -> bool:
        return not self.check_fns

    def has_expects(self) -> bool:
        return not self.no_expects()

    def check_as_expected(self, output_text: str) -> None:
        for cfn in self.check_fns:
            error = cfn(output_text)
            if error is not None:
                assert isinstance(error, UnexpectedShOutputError)
                raise error


_ExpShOutputSoftSingletonT = Union[str, ExpShOutputCheckFnT]

ExpShOutputSoftT = Union[
    _ExpShOutputSoftSingletonT, None, ExpShOutput, Iterable[_ExpShOutputSoftSingletonT]]


def mk_no_exp_sh_output() -> ExpShOutput:
    return ExpShOutput(check_fns=[])


def _mk_regexp_exp_sh_output_check_fn(pattern: str) -> ExpShOutputCheckFnT:
    def check_fn(in_text: str) -> ExpShOutputCheckFnOutT:
        found = re.search(pattern, in_text)
        if found is not None:
            return None

        return UnexpectedShOutputError(
            f"Cannot find regexp '{pattern}' in shell output: '''\n{in_text}\n'''"
        )

    return check_fn


def _mk_regexp_exp_sh_output(pattern: str) -> ExpShOutput:
    return ExpShOutput(check_fns=[_mk_regexp_exp_sh_output_check_fn(pattern)])


def _mk_singleton_exp_sh_check_fn(
        check_exp: Union[str, ExpShOutputCheckFnT]) -> ExpShOutputCheckFnT:
    if callable(check_exp):
        return check_exp

    assert isinstance(check_exp, str)
    return _mk_regexp_exp_sh_output_check_fn(check_exp)


def _mk_singleton_exp_sh_output(
        check_exp: Union[str, ExpShOutputCheckFnT]) -> ExpShOutput:
    return ExpShOutput(check_fns=[_mk_singleton_exp_sh_check_fn(check_exp)])


def _mk_multi_exp_sh_output(
        check_exps: Iterable[Union[str, ExpShOutputCheckFnT]]) -> ExpShOutput:
    check_fns = map(_mk_singleton_exp_sh_check_fn, check_exps)
    return ExpShOutput(check_fns=check_fns)


def ensure_exp_sh_output(val: ExpShOutputSoftT) -> ExpShOutput:
    if val is None:
        return mk_no_exp_sh_output()
    if isinstance(val, str):
        return _mk_regexp_exp_sh_output(val)

    if callable(val):
        return _mk_singleton_exp_sh_output(val)

    assert isinstance(val, Iterable)
    return _mk_multi_exp_sh_output(val)


def check_sh_output_is_empty(sh_output: str) -> ExpShOutputCheckFnOutT:
    stripped_out = sh_output.strip()
    if not stripped_out:
        return None

    return UnexpectedShOutputError(
        f"Expected empty shell output. Received instead: '''\n{sh_output}\n'''"
    )


@dataclass
class ExpShOutcome:
    status: ExpShStatus = field(default_factory=mk_no_exp_sh_status)
    stdout: ExpShOutput = field(default_factory=mk_no_exp_sh_output)
    stderr: ExpShOutput = field(default_factory=mk_no_exp_sh_output)

    def success(self) -> bool:
        return self.status.success()

    def has_status_expects(self) -> bool:
        return self.status.has_expects()

    def has_stdout_expects(self) -> bool:
        return self.stdout.has_expects()

    def has_stderr_expects(self) -> bool:
        return self.stderr.has_expects()

    def check_as_expected(
            self,
            status: Optional[int] = None,
            stdout: Optional[str] = None,
            stderr: Optional[str] = None) -> None:
        if status is None:
            assert not self.status.has_expects()
        else:
            try:
                self.status.check_as_expected(status)
            except UnexpectedShStatusError as e:
                raise UnexpectedStatusShOutcomeError from e

        if stdout is None:
            # It is a programmer error to forget to provide us stderr result
            # when he specified some expectations on stderr.
            # He most likely forgot to capture this output when calling a `subprocess`
            # function.
            assert not self.stdout.has_expects()
        else:
            try:
                self.stdout.check_as_expected(stdout)
            except UnexpectedShOutputError as e:
                raise UnexpectedStdOutShOutcomeError from e

        if stderr is None:
            # It is a programmer error to forget to provide us stderr result
            # when he specified some expectations on stderr.
            # He most likely forgot to capture this output when calling a `subprocess`
            # function.
            assert not self.stderr.check_fns
        else:
            try:
                self.stderr.check_as_expected(stderr)
            except UnexpectedShOutputError as e:
                raise UnexpectedStdErrShOutcomeError from e

    def check_expected_error(
            self, error: subprocess.CalledProcessError) -> None:
        # For the time being, we support only subprocess's errors.
        assert isinstance(error, subprocess.CalledProcessError)
        self._check_expected_called_process_error(error)

    def _check_expected_called_process_error(
            self, error: subprocess.CalledProcessError) -> None:
        self.check_as_expected(error.returncode, error.stdout, error.stderr)


ExpShOutcomeTupleT = Tuple[int, ExpShOutputSoftT, ExpShOutputSoftT]
ExpShOutcomeSoftT = Union[ExpShOutcome, ExpShOutcomeTupleT, int]


@dataclass
class ExpShOutcomeByCtx:
    unprivileged: ExpShOutcome
    privileged: ExpShOutcome


ExpShOutcomeByCtxTupleT = Tuple[
    ExpShOutcomeSoftT, ExpShOutcomeSoftT]
ExpShOutcomeByCtxSoftT = Union[
    ExpShOutcomeByCtx, ExpShOutcomeByCtxTupleT]


def _mk_exp_shell_outcome_from_soft_unpacked_tuple(
    status: ExpShStatusSoftT = None,
    stdout: ExpShOutputSoftT = None,
    stderr: ExpShOutputSoftT = None
) -> ExpShOutcome:
    return ExpShOutcome(
        ensure_exp_sh_status(status),
        ensure_exp_sh_output(stdout),
        ensure_exp_sh_output(stderr)
    )


def ensure_exp_shell_outcome(
        in_value: ExpShOutcomeSoftT
) -> ExpShOutcome:
    if isinstance(in_value, ExpShOutcome):
        return in_value
    if isinstance(in_value, int):
        return ExpShOutcome(ensure_exp_sh_status(in_value))

    assert isinstance(in_value, tuple)
    return _mk_exp_shell_outcome_from_soft_unpacked_tuple(*in_value)


def ensure_exp_shell_outcome_by_context(
        in_value: ExpShOutcomeByCtxSoftT
) -> ExpShOutcomeByCtx:
    if isinstance(in_value, ExpShOutcomeByCtx):
        return in_value

    # Allow the shortcut of specifying the same output
    # for the 2 contexts.
    if isinstance(in_value, ExpShOutcome) \
            or isinstance(in_value, int):
        in_value = (in_value,) * 2

    if isinstance(in_value, tuple) and 1 == len(in_value):
        in_value = (in_value[0], in_value[0])

    assert isinstance(in_value, tuple) and 2 == len(in_value)

    return ExpShOutcomeByCtx(
        *map(ensure_exp_shell_outcome, in_value))
