from dataclasses import dataclass
from typing import Optional, Tuple, Union


@dataclass
class ExpShellOutcome:
    status: int
    stdout_re: Optional[str] = None
    stderr_re: Optional[str] = None


ExpShellOutcomeTupleT = Tuple[int, Optional[str], Optional[str]]
ExpShellOutcomeSoftT = Union[ExpShellOutcome, ExpShellOutcomeTupleT, int]


@dataclass
class ExpShellOutcomeByContext:
    unprivileged: ExpShellOutcome
    privileged: ExpShellOutcome


ExpShellOutcomeByContextTupleT = Tuple[
    ExpShellOutcomeSoftT, ExpShellOutcomeSoftT]
ExpShellOutcomeByContextSoftT = Union[
    ExpShellOutcomeByContext, ExpShellOutcomeByContextTupleT]


def ensure_exp_shell_outcome(
        in_value: ExpShellOutcomeSoftT
) -> ExpShellOutcome:
    if isinstance(in_value, ExpShellOutcome):
        return in_value
    if isinstance(in_value, int):
        return ExpShellOutcome(in_value)

    return ExpShellOutcome(*in_value)


def ensure_exp_shell_outcome_by_context(
        in_value: ExpShellOutcomeByContextSoftT
) -> ExpShellOutcomeByContext:
    if isinstance(in_value, ExpShellOutcomeByContext):
        return in_value

    return ExpShellOutcomeByContext(
        *map(ensure_exp_shell_outcome, in_value))
