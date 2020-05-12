from typing import Optional


def prompt_for_user_approval(
        prompt_str: Optional[str] = None
) -> bool:
    if prompt_str is None:
        prompt_str = "Continue"

    r = input("{} (y/n)? ".format(prompt_str))
    print("\n")
    approval_given = (r == 'Y' or r == 'y')
    return approval_given
